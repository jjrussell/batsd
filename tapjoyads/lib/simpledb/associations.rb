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

        define_method(association_name) do
          association_id = send(foreign_key)
          return nil if association_id.blank?
          klass.find(association_id)
        end
        memoize association_name
      end
    end

  end
end
