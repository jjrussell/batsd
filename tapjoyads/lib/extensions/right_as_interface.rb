#
# Basic implementation of the ELB API.
#
# Most of this code was copied from the right_aws gem version 2.0.0 and modified to work with version 1.10.0
#

module RightAws
  class AsInterface < RightAwsBase
    include RightAwsBaseInterface

    # Amazon AS API version being used
    API_VERSION       = '2009-05-15'
    DEFAULT_HOST      = 'autoscaling.amazonaws.com'
    DEFAULT_PATH      = '/'
    DEFAULT_PROTOCOL  = 'https'
    DEFAULT_PORT      = 443

    @@bench = AwsBenchmarkingBlock.new
    def self.bench_xml
      @@bench.xml
    end
    def self.bench_service
      @@bench.service
    end

    # Create a new handle to an CSLS account. All handles share the same per process or per thread
    # HTTP connection to Amazon CSLS. Each handle is for a specific account. The params have the
    # following options:
    # * <tt>:endpoint_url</tt> a fully qualified url to Amazon API endpoint (this overwrites: :server, :port, :service, :protocol). Example: 'https://autoscaling.amazonaws.com/'
    # * <tt>:server</tt>: AS service host, default: DEFAULT_HOST
    # * <tt>:port</tt>: AS service port, default: DEFAULT_PORT
    # * <tt>:protocol</tt>: 'http' or 'https', default: DEFAULT_PROTOCOL
    # * <tt>:multi_thread</tt>: true=HTTP connection per thread, false=per process
    # * <tt>:logger</tt>: for log messages, default: RAILS_DEFAULT_LOGGER else STDOUT
    # * <tt>:signature_version</tt>:  The signature version : '0','1' or '2'(default)
    # * <tt>:cache</tt>: true/false(default): describe_auto_scaling_groups
    #
    def initialize(aws_access_key_id=nil, aws_secret_access_key=nil, params={})
      init({ :name                => 'AS',
             :default_host        => ENV['AS_URL'] ? URI.parse(ENV['AS_URL']).host   : DEFAULT_HOST,
             :default_port        => ENV['AS_URL'] ? URI.parse(ENV['AS_URL']).port   : DEFAULT_PORT,
             :default_service     => ENV['AS_URL'] ? URI.parse(ENV['AS_URL']).path   : DEFAULT_PATH,
             :default_protocol    => ENV['AS_URL'] ? URI.parse(ENV['AS_URL']).scheme : DEFAULT_PROTOCOL },
           aws_access_key_id    || ENV['AWS_ACCESS_KEY_ID'] ,
           aws_secret_access_key|| ENV['AWS_SECRET_ACCESS_KEY'],
           params)
    end

    def generate_request(action, params={}) #:nodoc:
      # generate_request_impl(:get, action, params )
      service_hash = {"Action"         => action,
                      "AWSAccessKeyId" => @aws_access_key_id,
                      "Version"        => API_VERSION }
      service_hash.update(params)
      service_params = signed_service_params(@aws_secret_access_key, service_hash, :get, @params[:server], @params[:service])
      request = Net::HTTP::Get.new("#{@params[:service]}?#{service_params}")
      # prepare output hash
      { :request  => request,
        :server   => @params[:server],
        :port     => @params[:port],
        :protocol => @params[:protocol] }
    end

    # Sends request to Amazon and parses the response
    # Raises AwsError if any banana happened
    def request_info(request, parser, &block)  #:nodoc:
      thread = @params[:multi_thread] ? Thread.current : Thread.main
      thread[:aass_connection] ||= Rightscale::HttpConnection.new(:exception => RightAws::AwsError, :logger => @logger)
      request_info_impl(thread[:aass_connection], @@bench, request, parser, &block)
    end

    # Format array of items into Amazons handy hash ('?' is a place holder):
    #
    #  amazonize_list('Item', ['a', 'b', 'c']) =>
    #    { 'Item.1' => 'a', 'Item.2' => 'b', 'Item.3' => 'c' }
    #
    #  amazonize_list('Item.?.instance', ['a', 'c']) #=>
    #    { 'Item.1.instance' => 'a', 'Item.2.instance' => 'c' }
    #
    #  amazonize_list(['Item.?.Name', 'Item.?.Value'], {'A' => 'a', 'B' => 'b'}) #=>
    #    { 'Item.1.Name' => 'A', 'Item.1.Value' => 'a',
    #      'Item.2.Name' => 'B', 'Item.2.Value' => 'b'  }
    #
    #  amazonize_list(['Item.?.Name', 'Item.?.Value'], [['A','a'], ['B','b']]) #=>
    #    { 'Item.1.Name' => 'A', 'Item.1.Value' => 'a',
    #      'Item.2.Name' => 'B', 'Item.2.Value' => 'b'  }
    #
    #  amazonize_list(['Filter.?.Key', 'Filter.?.Value.?'], {'A' => ['aa','ab'], 'B' => ['ba','bb']}) #=>
    #  amazonize_list(['Filter.?.Key', 'Filter.?.Value.?'], [['A',['aa','ab']], ['B',['ba','bb']]])   #=>
    #    {"Filter.1.Key"=>"A",
    #     "Filter.1.Value.1"=>"aa",
    #     "Filter.1.Value.2"=>"ab",
    #     "Filter.2.Key"=>"B",
    #     "Filter.2.Value.1"=>"ba",
    #     "Filter.2.Value.2"=>"bb"}
    def amazonize_list(masks, list) #:nodoc:
      groups = {}
      Array(list).each_with_index do |list_item, i|
        Array(masks).each_with_index do |mask, mask_idx|
          key = mask[/\?/] ? mask.dup : mask.dup + '.?'
          key.sub!('?', (i+1).to_s)
          value = Array(list_item)[mask_idx]
          if value.is_a?(Array)
            groups.merge!(amazonize_list(key, value))
          else
            groups[key] = value
          end
        end
      end
      groups
    end

    #-----------------------------------------------------------------
    #      Auto Scaling Groups
    #-----------------------------------------------------------------

    # Describe auto scaling groups.
    # Returns a full description of the AutoScalingGroups from the given list.
    # This includes all EC2 instances that are members of the group. If a list
    # of names is not provided, then the full details of all AutoScalingGroups
    # is returned. This style conforms to the EC2 DescribeInstances API behavior.
    #
    def describe_auto_scaling_groups(*auto_scaling_group_names)
      auto_scaling_group_names = auto_scaling_group_names.flatten.compact
      request_hash = amazonize_list('AutoScalingGroupNames.member', auto_scaling_group_names)
      link = generate_request("DescribeAutoScalingGroups", request_hash)
      request_cache_or_info(:describe_auto_scaling_groups, link,  DescribeAutoScalingGroupsParser, @@bench, auto_scaling_group_names.blank?)
    end

    #-----------------------------------------------------------------
    #      Trigger Operations
    #-----------------------------------------------------------------

    # Describe triggers.
    # Returns a full description of the trigger in the specified Auto Scaling Group.
    #
    #  as.describe_triggers('CentOS.5.1-c-array') #=>
    #      [{:status=>"HighBreaching",
    #        :breach_duration=>300,
    #        :measure_name=>"CPUUtilization",
    #        :trigger_name=>"kd.tr.1",
    #        :period=>60,
    #        :lower_threshold=>0.0,
    #        :lower_breach_scale_increment=>-1,
    #        :dimensions=>
    #         {"Namespace"=>"AWS",
    #          "AutoScalingGroupName"=>"CentOS.5.1-c-array",
    #          "Service"=>"EC2"},
    #        :statistic=>"Average",
    #        :upper_threshold=>10.0,
    #        :created_time=>Thu May 28 09:48:46 UTC 2009,
    #        :auto_scaling_group_name=>"CentOS.5.1-c-array",
    #        :upper_breach_scale_increment=>1}]
    #
    def describe_triggers(auto_scaling_group_name)
      link = generate_request("DescribeTriggers", 'AutoScalingGroupName' => auto_scaling_group_name)
      request_info(link, DescribeTriggersParser.new(:logger => @logger))
    end

    #-----------------------------------------------------------------
    #      PARSERS: Auto Scaling Groups
    #-----------------------------------------------------------------

    class DescribeAutoScalingGroupsParser < RightAWSParser #:nodoc:
      def tagstart(name, attributes)
        case name
        when 'member'
          case @xmlpath
            when @p then @item = { :instances => [ ],
                                   :availability_zones => [],
                                   :load_balancer_names => [] }
            when "#@p/member/Instances" then @instance = { }
          end
        end
      end
      def tagend(name)
        case name
        when 'CreatedTime'             then @item[:created_time]              = @text
        when 'MinSize'                 then @item[:min_size]                  = @text.to_i
        when 'MaxSize'                 then @item[:max_size]                  = @text.to_i
        when 'DesiredCapacity'         then @item[:desired_capacity]          = @text.to_i
        when 'Cooldown'                then @item[:cooldown]                  = @text.to_i
        when 'LaunchConfigurationName' then @item[:launch_configuration_name] = @text
        when 'AutoScalingGroupName'    then @item[:auto_scaling_group_name]   = @text
        when 'InstanceId'              then @instance[:instance_id]       = @text
        when 'LifecycleState'          then @instance[:lifecycle_state]   = @text
        when 'AvailabilityZone'        then @instance[:availability_zone] = @text
        when 'member'
          case @xmlpath
          when @p then
            @item[:availability_zones].sort!
            @result << @item
          when "#@p/member/AvailabilityZones" then @item[:availability_zones] << @text
          when "#@p/member/LoadBalancerNames" then @item[:load_balancer_names] << @text
          when "#@p/member/Instances"         then @item[:instances] << @instance
          end
        end
      end
      def reset
        @p      = 'DescribeAutoScalingGroupsResponse/DescribeAutoScalingGroupsResult/AutoScalingGroups'
        @result = []
      end
    end

    #-----------------------------------------------------------------
    #      PARSERS: Triggers
    #-----------------------------------------------------------------

    class DescribeTriggersParser < RightAWSParser #:nodoc:
      def tagstart(name, attributes)
        case name
        when 'member'
          case @xmlpath
          when 'DescribeTriggersResponse/DescribeTriggersResult/Triggers'
            @item = { :dimensions => {} }
          when 'DescribeTriggersResponse/DescribeTriggersResult/Triggers/member/Dimensions'
            @dimension = {}
          end
        end
      end
      def tagend(name)
        case name
        when 'AutoScalingGroupName'      then @item[:auto_scaling_group_name]      = @text
        when 'MeasureName'               then @item[:measure_name]                 = @text
        when 'CreatedTime'               then @item[:created_time]                 = @text
        when 'BreachDuration'            then @item[:breach_duration]              = @text.to_i
        when 'UpperBreachScaleIncrement' then @item[:upper_breach_scale_increment] = @text.to_i
        when 'UpperThreshold'            then @item[:upper_threshold]              = @text.to_f
        when 'LowerThreshold'            then @item[:lower_threshold]              = @text.to_f
        when 'LowerBreachScaleIncrement' then @item[:lower_breach_scale_increment] = @text.to_i
        when 'Period'                    then @item[:period]                       = @text.to_i
        when 'Status'                    then @item[:status]                       = @text
        when 'TriggerName'               then @item[:trigger_name]                 = @text
        when 'Statistic'                 then @item[:statistic]                    = @text
        when 'Unit'                      then @item[:unit]                         = @text
        when 'Name'                      then @dimension[:name]                    = @text
        when 'Value'                     then @dimension[:value]                   = @text
        when 'member'
          case @xmlpath
          when "#@p/member/Dimensions" then @item[:dimensions][@dimension[:name]] = @dimension[:value]
          when @p                      then @result << @item
          end
        end
      end
      def reset
        @p      = 'DescribeTriggersResponse/DescribeTriggersResult/Triggers'
        @result = []
      end
    end
  end

end
