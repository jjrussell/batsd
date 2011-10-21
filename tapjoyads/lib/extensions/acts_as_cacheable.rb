module ActsAsCacheable

  def self.included(base)
    base.extend ActsAsCacheable::ClassMethods
  end

  module ClassMethods
    def acts_as_cacheable
      extend ActiveSupport::Memoizable
      include ActsAsCacheable::InstanceMethods
      include ActiveSupport::Callbacks

      define_callbacks :before_cache, :after_cache, :before_cache_clear, :after_cache_clear

      after_commit_on_create :cache
      after_commit_on_update :cache
      after_commit_on_destroy :clear_cache

      class << self
        def cache_all
          find_each(&:cache)
        end

        def find_in_cache(id, do_lookup = (Rails.env != 'production'))
          object = Mc.distributed_get("mysql.#{model_name.underscore}.#{id}.#{SCHEMA_VERSION}")
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
    end
  end

  module InstanceMethods

    def cache
      run_callbacks(:before_cache)
      clear_association_cache
      Mc.distributed_put("mysql.#{self.class.model_name.underscore}.#{id}.#{SCHEMA_VERSION}", self, false, 1.day).tap do
        run_callbacks(:after_cache)
      end
    end

    def clear_cache
      run_callbacks(:before_cache_clear)
      Mc.distributed_delete("mysql.#{self.class.model_name.underscore}.#{id}.#{SCHEMA_VERSION}").tap do
        run_callbacks(:after_cache_clear)
      end
    end
  end

end

ActiveRecord::Base.send(:include, ActsAsCacheable)
