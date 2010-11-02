# Include this module in any ActiveRecord model that should have its records cached with memcached.

module MemcachedRecord

  def self.included(model)
    model.class_eval do
      after_save :update_memcached
      before_destroy :clear_memcached

      def model.find_in_cache(id, do_lookup = true)
        if do_lookup
          Mc.get_and_put("mysql.#{class_name.underscore}.#{id}") { find(id) }
        else
          Mc.get("mysql.#{class_name.underscore}.#{id}")
        end
      end
    end
  end

private

  def update_memcached
    Mc.put("mysql.#{self.class.class_name.underscore}.#{id}", self)
  end

  def clear_memcached
    Mc.delete("mysql.#{self.class.class_name.underscore}.#{id}")
  end

end
