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
        result << "conditions[:hosts].include?(env[:host])" if conditions[:hosts] && Rails.env.production?
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
      alias_method :orig_pk_and_sequence_for, :pk_and_sequence_for if self.respond_to?(:pk_and_sequence_for)

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
  # This prevents a savvy user from setting hidden fields by manipulating the DOM.
  #
  class Base
    alias_method :orig_readonly?, :readonly?

    def readonly?
      (connection.adapter_name == 'SQLite' && Rails.env.production?) || orig_readonly?
    end

    def safe_update_attributes(attributes, allowed_attr_names)
      allowed_attr_names = Set.new(allowed_attr_names.map { |v| v.to_s })
      attributes.keys.each do |k|
        if attributes[k].is_a? Hash
          attributes[k].keys.each do |nested_k|
            nested_k = "#{k}_#{nested_k}"
            raise RecordNotSaved.new("'#{nested_k}' is not in the list of allowed attributes.") unless allowed_attr_names.include?(nested_k.to_s)
          end
        else
          raise RecordNotSaved.new("'#{k}' is not in the list of allowed attributes.") unless allowed_attr_names.include?(k.to_s)
        end

      end
      self.update_attributes(attributes)
    end
  end
end

#
# This adds a currency_field that automatically converts a currency from cents to dollars.
#
module ActionView
  module Helpers
    class FormBuilder

      def currency_field(field, number_options = {}, options = {})
        html_classes = options[:class].nil? ? [] : options[:class].split(' ')
        html_classes << 'currency_field' unless html_classes.include?('currency_field')
        options.merge!({ :class => html_classes.join(' ') })
        options.merge!({ :value => number_to_currency(object.send(field) / 100.0, number_options) }) unless object.send(field).nil?
        text_field(field, options)
      end

      def email_field(method, options = {})
        @template.email_field(@object_name, method, objectify_options(options))
      end

      def chosen_select(method, choices, options = {}, html_options = {})
        select(method, choices, options, html_options.merge(:class => 'chosen'))
      end
    end

    module FormHelper
      # stolen from Rails3
      def email_field(object_name, method, options = {})
        InstanceTag.new(object_name, method, self, options.delete(:object)).to_input_field_tag("email", options)
      end
    end

    module FormTagHelper
      def email_field_tag(name, value = nil, options = {})
        tag :input, { "type" => "email", "name" => name, "id" => sanitize_to_id(name), "value" => value }.update(options.stringify_keys)
      end
    end
  end
end
