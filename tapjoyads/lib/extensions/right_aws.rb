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
    
    # Overwrite request_info to modify the :http_connection_read_timeout option from 120
    # and the :http_connection_retry_count option from 3.
    # This should help our servers not lock up when sdb goes down.
    def request_info(request, parser)
      thread = @params[:multi_thread] ? Thread.current : Thread.main
      thread[:sdb_connection] ||= Rightscale::HttpConnection.new(:exception => AwsError, :logger => @logger, :http_connection_read_timeout => 60, :http_connection_retry_count => 0)
      request_info_impl(thread[:sdb_connection], @@bench, request, parser)
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
end
