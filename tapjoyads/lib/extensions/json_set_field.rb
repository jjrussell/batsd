module JsonSetField

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def json_set_field(*fields)
      fields.each do |f|

        define_method "#{f}=" do |new_field_value|
          self[:"#{f}"] = if new_field_value.is_a?(String)
            new_field_value
          elsif new_field_value.is_a?(Array)
            new_field_value.reject! { |val| val.blank? }
            new_field_value.empty? ? '' : new_field_value.to_json
          else
            new_field_value.to_json
          end
        end

        define_method "get_#{f}" do
          Set.new((send(f).blank? || send(f) == '[]') ? nil : JSON.parse(send(f)))
        end

      end

      validates_each fields, :allow_blank => true do |record, attribute, value|
        begin
          record.errors.add(attribute, 'is not an Array') unless JSON.parse(value).is_a?(Array)
        rescue
          record.errors.add(attribute, 'is not valid JSON')
        end
      end

    end

  end

end

ActiveRecord::Base.send(:include, JsonSetField)
