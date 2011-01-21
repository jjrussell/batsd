# Include this module in any ActiveRecord model that should have its records cached with memcached.

module MemcachedRecord

  def self.included(model)
    model.class_eval do
      after_save :update_memcached
      after_destroy :clear_memcached

      def model.find_in_cache(id, do_lookup = false)
        if do_lookup
          Mc.distributed_get_and_put("mysql.#{class_name.underscore}.#{id}") { find(id) }
        else
          Mc.distributed_get("mysql.#{class_name.underscore}.#{id}")
        end
      end

      def model.cache_all
        find_each do |obj|
          obj.send(:update_memcached)
        end
      end
    end
  end

private

  def update_memcached
    Mc.distributed_put("mysql.#{self.class.class_name.underscore}.#{id}", self)
  end

  def clear_memcached
    Mc.distributed_delete("mysql.#{self.class.class_name.underscore}.#{id}")
  end

end
