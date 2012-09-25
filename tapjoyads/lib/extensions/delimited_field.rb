module DelimitedField

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def delimited_field(*fields)
      fields.each do |f|
        define_method "#{f}=" do |new_field_value|
          self[f.to_sym] = if (new_field_value.is_a?(Array) || new_field_value.is_a?(Set))
            new_field_value = new_field_value.to_a.reject { |val| val.blank? }
            new_field_value.join(';')
          else
            new_field_value.to_s
          end
        end

        define_method f do
          Set.new(read_attribute(f).to_s.split(';'))
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, DelimitedField)
