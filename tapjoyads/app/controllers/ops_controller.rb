class OpsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all

  def elb_status
    @lb_names     = Rails.env.production? ? %w( masterjob-lb job-lb website-lb dashboard-lb api-lb test-lb util-lb ) : []
    instance_ids  = []

    @lb_instances = get_lb_instances(@lb_names)
    @lb_names.each do |lb_name|
      instance_ids += @lb_instances[lb_name].map { |i| i[:instance_id] }
    end
    @ec2_instances = get_ec2_instances(instance_ids)
  end

  def as_groups
    @as_groups = get_as_groups
  end

  def index
    @as_groups = get_as_groups
    @as_groups.each do |group|
      group[:instances].reject! { |instance| instance[:lifecycle_state] == "InService" }
    end

    @lb_names = @as_groups.map { |group| group[:load_balancer_names].first }
    instance_ids = []

    @lb_instances = get_lb_instances(@lb_names)
    @lb_names.each do |lb_name|
      instance_ids += @lb_instances[lb_name].map { |i| i[:instance_id] }

      @lb_instances[lb_name].reject! { |i| i[:state] == 'InService' }
    end
    @ec2_instances = get_ec2_instances(instance_ids)
  end

  def service_stats
  end

  def http_codes
    redis = Redis.new(:host => "ec2-75-101-244-223.compute-1.amazonaws.com", :port => 6380)

    # Since the data is buffered by 10 seconds, start from 10 seconds ago
    @period = params[:period] ? params[:period].to_i.seconds : 60.seconds
    @end_time = Time.zone.now - 10.seconds
    @start_time = @end_time - @period

    respond_to do |format|
      format.json do
        @stats = {}
        keys = []
        time = @start_time.to_i
        while time <= @end_time.to_i
          if (time % 100 == 0) && (time + 100 < @end_time.to_i)
            keys += redis.keys("api.status.*.#{time.to_s[0..-3]}*")
            time += 100
          elsif (time % 10 == 0) && (time + 10 < @end_time.to_i)
            keys += redis.keys("api.status.*.#{time.to_s[0..-2]}*")
            time += 10
          else
            keys += redis.keys("api.status.*.#{time}")
            time += 1
          end
        end

        values = redis.mapped_mget(*keys)
        keys.each do |key|
          time = key.split(".")[3].to_i
          if @period >= 10.minutes
            time -= time % 60
          end
          @stats[time] ||= {}
          @stats[time][key.split(".")[2]] ||= 0
          @stats[time][key.split(".")[2]] += values[key].to_i
        end

        render :json => @stats.to_json
      end
    end
  end

  private

  def get_as_groups
    as_interface = RightAws::AsInterface.new
    @as_groups = as_interface.describe_auto_scaling_groups
    @as_groups.each do |group|
      group[:triggers] = as_interface.describe_triggers(group[:auto_scaling_group_name])
    end
    @as_groups.sort! { |a, b| a[:auto_scaling_group_name] <=> b[:auto_scaling_group_name] }
  end

  def get_lb_instances(lb_names)
    elb_interface  = RightAws::ElbInterface.new
    lb_instances = {}

    lb_names.each do |lb_name|
      lb_instances[lb_name] = elb_interface.describe_instance_health(lb_name).sort { |a, b| a[:instance_id] <=> b[:instance_id] }
    end

    lb_instances
  end

  def get_ec2_instances(instance_ids)
    ec2_interface  = RightAws::Ec2.new
    ec2_instances = {}

    instance_ids.in_groups_of(70, false) do |instances|
      ec2_interface.describe_instances(instances).each do |instance|
        ec2_instances[instance[:aws_instance_id]] = instance
      end
    end

    ec2_instances
  end

end
