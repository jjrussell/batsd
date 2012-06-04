module DelimitedField

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def delimited_field(*fields)
      fields.each do |f|
        define_method "#{f}=" do |new_field_value|
          self[:"#{f}"] = if new_field_value.is_a?(Array)
            new_field_value.reject! { |val| val.blank? }
            new_field_value.empty? ? '' : new_field_value.join(';')
            else
              new_field_value
          end
        end
      end

      validates_each fields, :allow_blank => true do |record, attribute, value|
        begin
          record.errors.add(attribute, 'is not an Array') unless value.split(';').is_a?(Array)
        rescue
          record.errors.add(attribute, 'cannot be parsed into an Array')
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, DelimitedField)