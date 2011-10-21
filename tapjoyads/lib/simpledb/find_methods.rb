module Simpledb
  def self.included(base)
    class << base

      public

      def find(*args)
        options = args.extract_options!
        case args.first
          when :all then find_every(options)
          when :first then find_initial(options)
          else find_by_id(args.first, options)
        end
      end

      def find_by_id(id, options = {})
        result = self.new(options.merge({:key => id}))
        result.new_record? ? nil : result
      end

      private

      def find_initial(options)
        if ancestors.include?(SimpledbShardedResource)
          all_domain_names.each do |domain|
            item = select(options.merge(:domain_name => domain, :limit => 1))[:items].first
            return item if item
          end
          nil
        else
          select(options.merge(:limit => 1))[:items].first
        end
      end

      def find_every(options)
        items = []
        if ancestors.include?(SimpledbShardedResource)
          all_domain_names.each do |domain|
            select(options.merge(:domain_name => domain)) do |item|
              items << item
            end
          end
        else
          select(options) do |item|
            items << item
          end
        end
        items
      end

    end
  end
end
