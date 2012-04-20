module Simpledb
  module Associations

    def self.included(base)
      base.extend Simpledb::Associations::ClassMethods
    end

    module ClassMethods
      include ActiveSupport::Memoizable

      def belongs_to(*args)
        options = args.extract_options!

        association_name = args.first
        foreign_key = options[:foreign_key] || "#{association_name}_id"
        klass = (options[:class_name] || association_name).to_s.classify.constantize
        ivar = "@#{association_name}"

        define_method(association_name) do
          if instance_variable_get(ivar).present?
            return instance_variable_get(ivar)
          end

          association_id = send(foreign_key)
          return nil if association_id.blank?
          instance_variable_set(ivar, klass.find(association_id))
        end
      end
    end

  end
end
