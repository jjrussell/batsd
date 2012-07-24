module Simpledb
  module Associations

    def self.included(base)
      base.extend Simpledb::Associations::ClassMethods
    end

    module ClassMethods

      def belongs_to(*args)
        options = args.extract_options!

        association_name = args.first
        foreign_key = options[:foreign_key] || "#{association_name}_id"
        klass = (options[:class_name] || association_name).to_s.classify.constantize
        ivar = "@#{association_name}"

        define_method(association_name) do |*args|
          reload = args.shift

          if !reload && instance_variable_get(ivar).present?
            return instance_variable_get(ivar)
          end

          association_id = send(foreign_key)
          val = association_id.blank? ? nil : klass.find(association_id)
          instance_variable_set(ivar, val)
        end
      end

    end

  end
end
