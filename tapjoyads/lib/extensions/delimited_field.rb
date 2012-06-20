module DelimitedField

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def delimited_field(*fields)
      fields.each do |f|
        define_method "#{f}=" do |new_field_value|
          self[:"#{f}"] = if (new_field_value.is_a?(Array) or new_field_value.is_a?(Set))
            new_field_value.reject! { |val| val.blank? }
            new_field_value.empty? ? '' : new_field_value.to_a.join(';')
          else
            new_field_value.to_s
          end
        end

        define_method "#{f}" do
          Set.new(super.split(';'))
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, DelimitedField)
