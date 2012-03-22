class OpsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all

  def index
  end

  def elb_status
    elb_interface  = RightAws::ElbInterface.new
    ec2_interface  = RightAws::Ec2.new
    @lb_names      = Rails.env.production? ? %w( masterjob-lb job-lb website-lb dashboard-lb api-lb test-lb util-lb ) : []
    @lb_instances  = {}
    @ec2_instances = {}
    @lb_names.each do |lb_name|
      @lb_instances[lb_name] = elb_interface.describe_instance_health(lb_name)
      instance_ids = @lb_instances[lb_name].map { |i| i[:instance_id] }
      instance_ids.in_groups_of(70) do |instances|
        instances.compact!
        ec2_interface.describe_instances(instances).each do |instance|
          @ec2_instances[instance[:aws_instance_id]] = instance
        end
      end

      @lb_instances[lb_name].sort! { |a, b| a[:instance_id] <=> b[:instance_id] }
    end
  end

  def as_groups
    as_interface = RightAws::AsInterface.new
    @as_groups = as_interface.describe_auto_scaling_groups
    @as_groups.each do |group|
      group[:triggers] = as_interface.describe_triggers(group[:auto_scaling_group_name])
    end
    @as_groups.sort! { |a, b| a[:auto_scaling_group_name] <=> b[:auto_scaling_group_name] }
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

end
