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
    now = Time.zone.now

    # Since the data is buffered by 10 seconds, start from 10 seconds ago
    @period = params[:period] ? params[:period].to_i : 60.seconds
    @end_time = params[:end_time] ? params[:end_time].to_i : (now - 10.seconds).to_i
    @start_time = @end_time - @period

    offset = 0
    if @period > 60.minutes
      offset = @start_time % 900
      @start_time -= 900 + offset
    elsif @period >= 30.minutes
      offset = @start_time % 60
      @start_time -= 60 + offset
    elsif @period >= 15.minutes
      offset = @start_time % 15
      @start_time -= 15 + offset
    end

    respond_to do |format|
      format.json do
        @stats = {}
        statuses = redis.smembers "api.statuses"
        keys = keys_in_time_range "api.status", statuses, @start_time, @end_time
        values = safe_mapped_mget(*keys)

        first_time = nil
        last_time = 0
        keys.each do |key|
          code = key.split(".")[2].to_i
          next  unless code > 0

          time = key.split(".")[3].to_i
          if @period > 60.minutes
            last_time = time -= (time % 900) + offset
          elsif @period >= 30.minutes
            last_time = time -= (time % 60) + offset
          elsif @period >= 10.minutes
            last_time = time -= (time % 15) + offset
          end
          first_time = time  unless first_time

          @stats[time] ||= {}
          @stats[time][code] ||= 0
          @stats[time][code] += values[key].to_i
        end
        @stats.delete last_time  if last_time > 0
        @stats.delete first_time if first_time

        render :json => @stats.to_json
      end
    end
  end

  def bytes_sent
    now = Time.zone.now

    # Since the data is buffered by 10 seconds, start from 10 seconds ago
    @period = params[:period] ? params[:period].to_i : 60.seconds
    @end_time = params[:end_time] ? params[:end_time].to_i : (now - 10.seconds).to_i
    @start_time = @end_time - @period

    offset = 0
    if @period > 60.minutes
      offset = @start_time % 900
      @start_time -= 900 + offset
    elsif @period >= 30.minutes
      offset = @start_time % 60
      @start_time -= 60 + offset
    elsif @period >= 15.minutes
      offset = @start_time % 15
      @start_time -= 15 + offset
    end

    respond_to do |format|
      format.json do
        @stats = {}
        keys = keys_in_time_range "api", "body_bytes_sent", @start_time, @end_time
        values = safe_mapped_mget(*keys)

        first_time = nil
        last_time = 0
        keys.each do |key|
          time = key.split(".")[2].to_i
          if @period > 60.minutes
            last_time = time -= (time % 900) + offset
          elsif @period >= 30.minutes
            last_time = time -= (time % 60) + offset
          elsif @period >= 10.minutes
            last_time = time -= (time % 15) + offset
          end
          first_time = time  unless first_time

          @stats[time] ||= 0
          @stats[time] += values[key].to_i
        end
        @stats.delete last_time  if last_time > 0
        @stats.delete first_time if first_time

        values = {}
        values["data"] = []
        values["name"] = "Bytes Sent"
        values["color"] = "green"
        @stats.each do |x,y|
          values["data"] << { :x => x, :y => y }
        end
        values["data"].sort! { |a,b| a[:x] <=> b[:x] }

        render :json => [values].to_json
      end
    end
  end

  private

  def redis
    @redis ||= Redis.new(:host => "redis.tapjoy.net", :port => 6380)
  end

  # Creates list of keys to lookup in redis based on time
  #
  # @param [String] namespace the namespace in redis to use
  # @param [Array, String] subkeys a set of subkeys (1 or more) to search on
  # @param [Integer] start_time the beginning of the keyset
  # @param [Integer] end_time the end of the keyset
  # @return [Array] the full key listing to look up
  def keys_in_time_range(namespace, subkeys, start_time, end_time)
    keys = []
    time = start_time

    start_time.to_i.upto(end_time.to_i) do |t|
      if subkeys.is_a? Array
        subkeys.each do |subkey|
          keys << "#{namespace}.#{subkey}.#{t}"
        end
      else
        keys << "#{namespace}.#{subkeys}.#{t}"
      end
    end

    keys
  end

  # Splits redis#mapped_mget into sections of 50_000 if necessary
  #
  # @param [Array] *keys the list of keys needed from redis
  # @return [Hash] mapped hash of keys => values
  def safe_mapped_mget(*keys)
    values = {}

    if keys.length >= 50_000
      working_keys = keys.dup
      while working_keys.length > 0
        puts "#{working_keys.length} keys left"
        working_values = redis.mapped_mget(*working_keys[0..49_999])
        values.update(working_values)
        working_keys.slice!(0..49_999)
      end
    else
      values = redis.mapped_mget(*keys)
    end

    values
  end

end
