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
      
      after_save :cache
      after_destroy :clear_cache
      
      class << self
        def cache_all
          find_each(&:cache)
        end

        def find_in_cache(id, do_lookup = (Rails.env != 'production'))
          if do_lookup
            Mc.distributed_get_and_put("mysql.#{class_name.underscore}.#{id}.#{SCHEMA_VERSION}", false, 1.day) { find(id) }
          else
            Mc.distributed_get("mysql.#{class_name.underscore}.#{id}.#{SCHEMA_VERSION}")
          end
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
      Mc.distributed_put("mysql.#{self.class.class_name.underscore}.#{id}.#{SCHEMA_VERSION}", self, false, 1.day)
      run_callbacks(:after_cache)
    end

    def clear_cache
      run_callbacks(:before_cache_clear)
      Mc.distributed_delete("mysql.#{self.class.class_name.underscore}.#{id}.#{SCHEMA_VERSION}")
      run_callbacks(:after_cache_clear)
    end
  end

end

ActiveRecord::Base.send(:include, ActsAsCacheable)