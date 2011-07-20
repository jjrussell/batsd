module JsonMultiField
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    
    def json_multi_field(*fields)
      fields.each do |f|
        
        define_method "#{f}=" do |new_field_value|
          self[:"#{f}"] = if new_field_value.is_a?(String)
            new_field_value
          elsif new_field_value.is_a?(Array)
            new_field_value.reject { |val| val.blank? }.to_json
          else
            new_field_value.to_json
          end        
        end
        
        define_method "get_#{f}" do
          Set.new(send(f).blank? ? nil : JSON.parse(send(f)))
        end
        
      end
    end
    
  end
  
end

ActiveRecord::Base.send(:include, JsonMultiField)