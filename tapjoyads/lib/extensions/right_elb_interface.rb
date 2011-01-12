#
# Basic implementation of the ELB API.
#
# Most of this code was copied from the right_aws gem version 2.0.0 and modified to work with version 1.10.0
#

module RightAws
  class ElbInterface < RightAwsBase
    include RightAwsBaseInterface

    # Amazon ELB API version being used
    API_VERSION       = "2009-11-25"
    DEFAULT_HOST      = "elasticloadbalancing.amazonaws.com"
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

    # Create a new handle to an ELB account. All handles share the same per process or per thread
    # HTTP connection to Amazon ELB. Each handle is for a specific account. The params have the
    # following options:
    # * <tt>:endpoint_url</tt> a fully qualified url to Amazon API endpoint (this overwrites: :server, :port, :service, :protocol). Example: 'https://elasticloadbalancing.amazonaws.com'
    # * <tt>:server</tt>: ELB service host, default: DEFAULT_HOST
    # * <tt>:port</tt>: ELB service port, default: DEFAULT_PORT
    # * <tt>:protocol</tt>: 'http' or 'https', default: DEFAULT_PROTOCOL
    # * <tt>:multi_thread</tt>: true=HTTP connection per thread, false=per process
    # * <tt>:logger</tt>: for log messages, default: RAILS_DEFAULT_LOGGER else STDOUT
    # * <tt>:signature_version</tt>:  The signature version : '0','1' or '2'(default)
    # * <tt>:cache</tt>: true/false(default): caching works for: describe_load_balancers
    #
    def initialize(aws_access_key_id=nil, aws_secret_access_key=nil, params={})
      init({ :name                => 'ELB',
             :default_host        => ENV['ELB_URL'] ? URI.parse(ENV['ELB_URL']).host   : DEFAULT_HOST,
             :default_port        => ENV['ELB_URL'] ? URI.parse(ENV['ELB_URL']).port   : DEFAULT_PORT,
             :default_service     => ENV['ELB_URL'] ? URI.parse(ENV['ELB_URL']).path   : DEFAULT_PATH,
             :default_protocol    => ENV['ELB_URL'] ? URI.parse(ENV['ELB_URL']).scheme : DEFAULT_PROTOCOL },
           aws_access_key_id    || ENV['AWS_ACCESS_KEY_ID'] ,
           aws_secret_access_key|| ENV['AWS_SECRET_ACCESS_KEY'],
           params)
    end

    def generate_request(action, params={}) #:nodoc:
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
      thread[:lbs_connection] ||= Rightscale::HttpConnection.new(:exception => RightAws::AwsError, :logger => @logger)
      request_info_impl(thread[:lbs_connection], @@bench, request, parser, &block)
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
    #      Instances
    #-----------------------------------------------------------------

    # Describe the current state of the instances of the specified load balancer.
    # Returns a list of the instances.
    #
    #  elb.describe_instance_health('test-kd1', 'i-8b8bcbe2', 'i-bf8bcbd6') #=>
    #      [ { :description => "Instance registration is still in progress",
    #          :reason_code => "ELB",
    #          :instance_id => "i-8b8bcbe2",
    #          :state       => "OutOfService" },
    #        { :description => "Instance has failed at least the UnhealthyThreshold number of health checks consecutively.",
    #          :reason_code => "Instance",
    #          :instance_id => "i-bf8bcbd6",
    #          :state       => "OutOfService" } ]
    #
    def describe_instance_health(load_balancer_name, *instances)
      instances.flatten!
      request_hash = amazonize_list("Instances.member.?.InstanceId", instances)
      request_hash.merge!( 'LoadBalancerName' => load_balancer_name )
      link = generate_request("DescribeInstanceHealth", request_hash)
      request_info(link, DescribeInstanceHealthParser.new(:logger => @logger))
    end

    # Add new instance(s) to the load balancer.
    # Returns an updated list of instances for the load balancer.
    #
    #  elb.register_instances_with_load_balancer('test-kd1', 'i-8b8bcbe2', 'i-bf8bcbd6') #=> ["i-8b8bcbe2", "i-bf8bcbd6"]
    #
    def register_instances_with_load_balancer(load_balancer_name, *instances)
      instances.flatten!
      request_hash = amazonize_list("Instances.member.?.InstanceId", instances)
      request_hash.merge!( 'LoadBalancerName' => load_balancer_name )
      link = generate_request("RegisterInstancesWithLoadBalancer", request_hash)
      request_info(link, InstancesWithLoadBalancerParser.new(:logger => @logger))
    end

    # Remove instance(s) from the load balancer.
    # Returns an updated list of instances for the load balancer.
    #
    #  elb.deregister_instances_with_load_balancer('test-kd1', 'i-8b8bcbe2') #=> ["i-bf8bcbd6"]
    #
    def deregister_instances_with_load_balancer(load_balancer_name, *instances)
      instances.flatten!
      request_hash = amazonize_list("Instances.member.?.InstanceId", instances)
      request_hash.merge!( 'LoadBalancerName' => load_balancer_name )
      link = generate_request("DeregisterInstancesFromLoadBalancer", request_hash)
      request_info(link, InstancesWithLoadBalancerParser.new(:logger => @logger))
    end

    #-----------------------------------------------------------------
    #      PARSERS: Instances
    #-----------------------------------------------------------------

    class DescribeInstanceHealthParser < RightAWSParser #:nodoc:
      def tagstart(name, attributes)
        @item = {} if name == 'member'
      end
      def tagend(name)
        case name
        when 'Description' then @item[:description] = @text
        when 'State'       then @item[:state]       = @text
        when 'InstanceId'  then @item[:instance_id] = @text
        when 'ReasonCode'  then @item[:reason_code] = @text
        when 'member'      then @result            << @item
        end
      end
      def reset
        @result = []
      end
    end

    class InstancesWithLoadBalancerParser < RightAWSParser #:nodoc:
      def tagend(name)
        case name
        when 'InstanceId'
          @result << @text
        when 'Instances'
          @result.sort!
        end
      end
      def reset
        @result = []
      end
    end

  end
end
