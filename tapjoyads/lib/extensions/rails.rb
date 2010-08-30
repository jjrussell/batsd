#
# This allows us to do conditional routing based on the requested host.
#
# example usage:
# map.with_options :conditions => { :hosts => [ 'example.com' ] } do |limited_route|
#   limited_route.resources :some_resource
# end
#
module ActionController
  module Routing
    
    class RouteSet
      alias_method :orig_extract_request_environment, :extract_request_environment
      
      def extract_request_environment(request)
        orig_extract_request_environment(request).merge({ :host => request.host })
      end
    end
    
    class Route
      alias_method :orig_recognition_conditions, :recognition_conditions
      
      def recognition_conditions
        result = orig_recognition_conditions
        result << "conditions[:hosts].include?(env[:host])" if conditions[:hosts] && Rails.env == 'production'
        result
      end
    end
    
  end
end

#
# This adds a _with_time logging method for each log severity level.
# It will time how long it takes to execute a block and append the
# number of seconds to the log message.
#
# example usage:
# Rails.logger.info_with_time('some message') do
#   method_that_takes_25_seconds
# end
#
# resulting log output: "some message (25s)"
#
module ActiveSupport
  class BufferedLogger
    
    for severity in Severity.constants
      class_eval <<-EOT, __FILE__, __LINE__
        def #{severity.downcase}_with_time(message)                 # def debug_with_time(message)
          start_time = Time.zone.now                                #   start_time = Time.zone.now
          yield                                                     #   yield
          message += ' (' + (Time.zone.now - start_time).to_s + ')' #   message += ' (' + (Time.zone.now - start_time).to_s + ')'
          add(#{severity}, message)                                 #   add(DEBUG, message)
        end                                                         # end
      EOT
    end
    
  end
end

module ActiveRecord
  module ConnectionAdapters
    
    #
    # This patch allows the schema-dumper to function correctly for tables
    # where the primary key column is called 'id' and is NOT an integer.
    #
    class MysqlAdapter
      alias_method :orig_pk_and_sequence_for, :pk_and_sequence_for
      
      def pk_and_sequence_for(table)
        keys = []
        result = execute("describe #{quote_table_name(table)}")
        result.each_hash do |h|
          keys << h["Field"] if h["Key"] == "PRI" && h["Type"] == "int(11)"
        end
        result.free
        keys.length == 1 ? [ keys.first, nil ] : nil
      end
    end
  end
  
  #
  # This patch allows us to specify which attributes are safe to update.
  # This prevents a savy user from setting hidden fields by manipulating the DOM.
  #
  class Base
    def safe_update_attributes(attributes, allowed_attr_names)
      allowed_attr_names = Set.new(allowed_attr_names.map { |v| v.to_s })
      attributes.keys.each do |k|
        raise RecordNotSaved.new("'#{k}' is not in the list of allowed attributes.") unless allowed_attr_names.include?(k.to_s)
      end
      self.update_attributes(attributes)
    end
  end
end

module ActionView
  module Helpers
    class FormBuilder
      include ActionView::Helpers::NumberHelper
      def currency_field(field, number_options={}, options={})
        options.merge!({:value => number_to_currency(object.send(field) / 100.0, number_to_currency)})
        text_field(field, options)
      end
    end
  end
end
