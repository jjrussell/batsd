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
    def info_with_time(message)
      start_time = Time.zone.now
      yield
      message += " (#{Time.zone.now - start_time})"
      add(INFO, message)
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

  class Base

    # ensure API servers are readonly
    alias_method :orig_readonly?, :readonly?
    cattr_accessor :readonly
    def readonly?
      self.readonly || orig_readonly?
    end

    # This patch allows us to specify which attributes are safe to update.
    # This prevents a savvy user from setting hidden fields by manipulating the DOM.
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

    def self.sanitize_conditions(*ary)
      self.sanitize_sql_array(ary.first.is_a?(Array) ? ary.first : ary)
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
        options.merge!({ :value => ::NumberHelper.number_to_currency(object.send(field) / 100.0, number_options) }) unless object.send(field).nil?
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
