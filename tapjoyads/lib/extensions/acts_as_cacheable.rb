module ActsAsCacheable

  def self.included(base)
    base.extend ActsAsCacheable::ClassMethods
  end

  module ClassMethods
    def acts_as_cacheable
      @acts_as_cacheable_version = Digest::MD5.hexdigest(connection.columns(table_name).collect { |c| [c.name,c.type] }.sort.join)

      extend ActiveSupport::Memoizable
      include ActsAsCacheable::InstanceMethods
      include ActiveSupport::Callbacks

      define_callbacks :before_cache, :after_cache, :before_cache_clear, :after_cache_clear, :cache_associations

      after_commit_on_create :cache
      after_commit_on_update :cache
      after_commit_on_destroy :clear_cache

      class << self
        attr_reader :acts_as_cacheable_version

        def cache_all(check_version = false)
          return false if check_version && version_cached?

          find_each(&:cache)
          cache_version

          true
        end

        def find_in_cache(id, do_lookup = !Rails.env.production?)
          object = Mc.distributed_get(cache_key_for(id))
          if object.nil? && do_lookup
            object = find(id)
            object.cache
          end
          object
        end

        def memoize_with_cache(*methods)
          before_cache(*methods)
          memoize_without_cache(*methods)
        end
        alias_method_chain :memoize, :cache
      end

      def cache_key_for(id)
        "mysql.#{model_name.underscore}.#{id}.#{acts_as_cacheable_version}"
      end

      def cache_version
        Mc.put(cache_key_for("version"), true, false, 1.day)
      end

      def version_cached?
        Mc.get(cache_key_for("version")).present?
      end
    end
  end

  module InstanceMethods

    def cache
      run_callbacks(:before_cache)
      clear_association_cache
      run_callbacks(:cache_associations)
      Mc.distributed_put(cache_key, self, false, 1.day).tap do
        run_callbacks(:after_cache)
      end
    end

    def clear_cache
      run_callbacks(:before_cache_clear)
      Mc.distributed_delete(cache_key).tap do
        run_callbacks(:after_cache_clear)
      end
    end

    private
    def cache_key
      self.class.cache_key_for(id)
    end
  end

end

ActiveRecord::Base.send(:include, ActsAsCacheable)
