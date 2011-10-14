module RightAws
  class SdbInterface

    # Override, in order to support consistency.
    silence_warnings do
      API_VERSION = '2009-04-15'
    end

    alias_method :orig_pack_attributes,   :pack_attributes
    alias_method :orig_put_attributes,    :put_attributes
    alias_method :orig_delete_attributes, :delete_attributes
    alias_method :orig_request_info,      :request_info
    alias_method :orig_get_attributes,    :get_attributes
    alias_method :orig_generate_request,  :generate_request

    def generate_request(action, params={}) #:nodoc:
      # remove empty params from request
      params.delete_if {|key,value| value.nil? }
      #params_string  = params.to_a.collect{|key,val| key + "=#{CGI::escape(val.to_s)}" }.join("&")
      # prepare service data
      service = '/'
      service_hash = {"Action"         => action,
                      "AWSAccessKeyId" => @aws_access_key_id,
                      "Version"        => API_VERSION }
      service_hash.update(params)
      service_params = signed_service_params(@aws_secret_access_key, service_hash, :get, @params[:server], service)
      #
      # use POST method if the length of the query string is too large
      # see http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/MakingRESTRequests.html
      if service_params.size > 2000
        if signature_version == '2'
          # resign the request because HTTP verb is included into signature
          service_params = signed_service_params(@aws_secret_access_key, service_hash, :post, @params[:server], service)
        end
        request      = Net::HTTP::Post.new(service)
        request.body = service_params
        request['Content-Type'] = 'application/x-www-form-urlencoded; charset=utf-8'
      else
        request = Net::HTTP::Get.new("#{service}?#{service_params}")
      end
      # prepare output hash
      { :request  => request, 
        :server   => @params[:server],
        :port     => @params[:port],
        :protocol => @params[:protocol] }
    end

    # Prepare attributes for putting or deleting.
    # (used by put_attributes, delete_attributes and batch_put_attributes)
    def pack_attributes(attributes, replace = false, expected_attr = {})
      result = {}
      if attributes
        idx = 0
        skip_values = attributes.is_a?(Array)
        attributes.each do |attribute, values|
          # set replacement attribute
          if replace == true || (replace.kind_of?(Enumerable) && replace.include?(attribute))
            result["Attribute.#{idx}.Replace"] = 'true'
          end

          # set expected attribute
          if expected_attr.include?(attribute)
            result["Expected.#{idx}.Name"] = attribute
            if expected_attr[attribute].nil?
              result["Expected.#{idx}.Exists"] = 'false'
            else
              result["Expected.#{idx}.Value"] = expected_attr[attribute]
            end
          end

          # pack Name/Value
          values = [nil] if values.nil?
          Array(values).each do |value|
            result["Attribute.#{idx}.Name"] = attribute
            unless skip_values || values == :all
              result["Attribute.#{idx}.Value"] = ruby_to_sdb(value)
            end
            idx += 1
          end
        end
      end
      result
    end

    def put_attributes(domain_name, item_name, attributes, replace = false, expected_attr = {})
      params = { 'DomainName' => domain_name, 'ItemName' => item_name }.merge(pack_attributes(attributes, replace, expected_attr))
      link = generate_request("PutAttributes", params)
      request_info( link, QSdbSimpleParser.new )
    rescue Exception
      on_exception
    end

    def delete_attributes(domain_name, item_name, attributes = nil, expected_attr = {})
      params = { 'DomainName' => domain_name, 'ItemName' => item_name }.merge(pack_attributes(attributes, false, expected_attr))
      link = generate_request("DeleteAttributes", params)
      request_info( link, QSdbSimpleParser.new )
    rescue Exception
      on_exception
    end

    # Add/Replace item attributes in Batch mode.
    # By using Amazon SDB BatchPutAttributes rather than PutAttributes this
    # method achieves a 15x-20x speed improvement when storing big quantities
    # of attributes.
    #
    # Params:
    #  domain_name = DomainName
    #  items = {
    #    'itemname' => {
    #      'attributeA' => [valueA1,..., valueAN],
    #      ...
    #      'attributeZ' => [valueZ1,..., valueZN]
    #    }
    #  }
    #  replace = :replace | any other value to skip replacement
    #
    # Returns a hash: { :box_usage, :request_id } on success or an exception on error. 
    #
    # see: http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/SDB_API_BatchPutAttributes.html 
    def batch_put_attributes(domain_name, items, replace = false)
      params = { 'DomainName' => domain_name }
      item_count = 0
      items.each_pair do |item_name, attributes|
        params["Item.#{item_count}.ItemName"] = item_name
        pack_attributes(attributes, replace).each_pair do |attr_key, attr_value|
          params["Item.#{item_count}.#{attr_key}"] = attr_value
        end
        item_count += 1
      end
      link = generate_request("BatchPutAttributes", params)
      request_info( link, QSdbSimpleParser.new )
    rescue Exception
      on_exception
    end

    def domain_metadata(domain_name)
      params = { 'DomainName' => domain_name }
      link = generate_request("DomainMetadata", params)
      request_info(link, QSdbDomainMetadataParser.new)
    rescue Exception
      on_exception
    end

    def get_attributes(domain_name, item_name, attribute_name=nil, consistent = false)
      link = generate_request("GetAttributes", 'DomainName'     => domain_name,
                                               'ItemName'       => item_name,
                                               'AttributeName'  => attribute_name,
                                               'ConsistentRead' => consistent )
      res = request_info(link, QSdbGetAttributesParser.new)
      res[:attributes].each_value do |values|
        values.collect! { |e| sdb_to_ruby(e) }
      end
      res
    rescue Exception
      on_exception
    end

    def select(select_expression, next_token = nil, consistent = false)
      select_expression      = query_expression_from_array(select_expression) if select_expression.is_a?(Array)
      @last_query_expression = select_expression
      #
      request_params = { 'SelectExpression' => select_expression,
                         'NextToken'        => next_token,
                         'ConsistentRead'   => consistent }
      link   = generate_request("Select", request_params)
      result = select_response_to_ruby(request_info( link, QSdbSelectParser.new ))
      return result unless block_given?
      # loop if block if given
      begin
        # the block must return true if it wanna continue
        break unless yield(result) && result[:next_token]
        # make new request
        request_params['NextToken'] = result[:next_token]
        link   = generate_request("Select", request_params)
        result = select_response_to_ruby(request_info( link, QSdbSelectParser.new ))
      end while true
    rescue Exception
      on_exception
    end

    class QSdbDomainMetadataParser < RightAWSParser #:nodoc:
      def reset
        @result = {}
      end
      def tagend(name)
        case name
        when 'BoxUsage'  then @result[:box_usage]  =  @text
        when 'RequestId' then @result[:request_id] =  @text

        when 'ItemCount'                then @result[:item_count]                  =  @text.to_i
        when 'ItemNamesSizeBytes'       then @result[:item_name_size_bytes]        =  @text.to_i
        when 'AttributeNameCount'       then @result[:attribute_name_count]        =  @text.to_i
        when 'AttributeNamesSizeBytes'  then @result[:attribute_names_size_bytes]  =  @text.to_i  
        when 'AttributeValueCount'      then @result[:attribute_value_count]       =  @text.to_i
        when 'AttributeValuesSizeBytes' then @result[:attribute_values_size_bytes] =  @text.to_i 
        when 'Timestamp'                then @result[:timestamp]                   =  Time.zone.at(@text.to_i)
        end
      end
    end
  end

  class  AcfInterface < RightAwsBase

    # Override, in order to support invalidation.
    silence_warnings do
      API_VERSION = '2010-11-01'
    end

    def invalidate(aws_id, paths, caller_reference)
      paths_str = ''
      paths.each do |path|
        paths_str << "<Path>#{path}</Path>"
      end

      body = <<-EOXML
        <?xml version="1.0" encoding="UTF-8"?>
        <InvalidationBatch>
           #{paths_str}
           <CallerReference>#{caller_reference}</CallerReference>
        </InvalidationBatch>
      EOXML

      request_hash = generate_request('POST', "distribution/#{aws_id}/invalidation", body.strip)
      request_info(request_hash, AcfInvalidationParser.new)
    end

    class AcfInvalidationParser < RightAWSParser #:nodoc:
      def reset
        @result = {}
      end
      def tagend(name)
        case name
        when 'Id'         then @result[:id]          = @text
        when 'Status'     then @result[:status]      = @text
        when 'CreateTime' then @result[:create_time] = @text
        end
      end
    end
  end

  class SqsGen2Interface
    alias_method :orig_generate_post_request, :generate_post_request

    def generate_post_request(action, param={})  # :nodoc:
      service = param[:queue_url] ? URI(param[:queue_url]).path : '/'
      message   = param[:message]                # extract message body if nesessary
      param.each{ |key, value| param.delete(key) if (value.nil? || key.is_a?(Symbol)) }
      service_hash = { "Action"           => action,
                       "Expires"          => (Time.now + REQUEST_TTL).utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
                       "AWSAccessKeyId"   => @aws_access_key_id,
                       "MessageBody"      => message,
                       "Version"          => API_VERSION }
      service_hash.update(param)

      service_params = signed_service_params(@aws_secret_access_key, service_hash, :post, @params[:server], service)
      request        = Net::HTTP::Post.new(AwsUtils::URLencode(service))
      request['Content-Type'] = 'application/x-www-form-urlencoded; charset=utf-8' 
      request.body = service_params
        # prepare output hash
      { :request  => request, 
        :server   => @params[:server],
        :port     => @params[:port],
        :protocol => @params[:protocol] }
    end

    def get_extra_queue_attributes(queue_url, attribute='All')
      req_hash = generate_request('GetQueueAttributes', 'AttributeName' => attribute, 'Version' => '2009-02-01', :queue_url  => queue_url)
      request_info(req_hash, SqsGetQueueAttributesParser.new(:logger => @logger))
    rescue
      on_exception
    end

    def get_queue_length_not_visible(queue_url)
      get_extra_queue_attributes(queue_url)['ApproximateNumberOfMessagesNotVisible'].to_i
    rescue
      on_exception
    end
  end

  class SqsGen2
    class Queue
      def get_extra_attribute(attribute='All')
        attributes = @sqs.interface.get_extra_queue_attributes(@url, attribute)
        attribute=='All' ? attributes : attributes[attribute]
      end

      def size_not_visible
        @sqs.interface.get_queue_length_not_visible(@url)
      end
    end
  end

end
