module ActsAsCacheable

  def self.included(base)
    base.extend ActsAsCacheable::ClassMethods
  end

  module ClassMethods
    def acts_as_cacheable

      @acts_as_cacheable_memoized_methods = []

      extend ActiveSupport::Memoizable
      include ActsAsCacheable::InstanceMethods
      include ActiveSupport::Callbacks

      define_callbacks :cache, :cache_clear, :cache_associations

      after_commit :cache, :on => :create
      after_commit :cache, :on => :update
      after_commit :clear_cache, :on => :destroy

      class << self
        attr_reader :acts_as_cacheable_memoized_methods

        def acts_as_cacheable_columns
          @acts_as_cacheable_columns ||= connection.columns(table_name).collect { |c| [c.name,c.type] }
        end

        def acts_as_cacheable_version
          @acts_as_cacheable_version ||= Digest::MD5.hexdigest((acts_as_cacheable_columns.sort.join + acts_as_cacheable_memoized_methods.sort.join))
        end

        def cache_all(check_version = false)
          return false if check_version && version_cached?

          cached_count = 0
          total_count = count
          start_time = last_time = Time.zone.now
          find_each do |record|
            record.cache
            cached_count += 1
            now_time = Time.zone.now
            if now_time - last_time > 10.seconds
              last_time = now_time
              percentage = '%.2f' % (cached_count.to_f / total_count * 100)
              elapsed = (last_time - start_time).to_i
              puts "#{last_time.to_i}: #{cached_count}/#{total_count} records (#{percentage}%) cached in #{elapsed}s"
            end
          end
          cache_version

          true
        end

        def find_in_cache(id, options = {})
          return nil unless id.uuid?
          do_lookup              = options.delete(:do_lookup) { !Rails.env.production? }
          queue_record_not_found = options.delete(:queue) { false }
          raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

          object = Mc.distributed_get(cache_key_for(id))
          if object.nil?
            if queue_record_not_found
              message = { :model_name => model_name, :id => id }.to_json
              Sqs.send_message(QueueNames::CACHE_RECORD_NOT_FOUND, message)
            end
            if do_lookup
              ActiveRecordDisabler.with_queries_enabled do
                find_by_id(id).tap { |object| object.try(:cache) }
              end
            end
          end
          object
        end

        def memoize_with_cache(*methods)
          @acts_as_cacheable_version = nil
          @acts_as_cacheable_memoized_methods |= methods
          methods.each do |m|
            set_callback :cache, :before, m.to_sym
          end
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
      begin
        run_callbacks :cache do
          clear_association_cache
          run_callbacks :cache_associations
          Mc.distributed_put(cache_key, self, false, 1.day)
        end
      rescue Exception => e
        Notifier.alert_new_relic(CacheFailure, e.message)
        raise e
      end
    end

    def clear_cache
      run_callbacks :cache_clear do
        Mc.distributed_delete(cache_key)
      end
    end

    private
    def cache_key
      self.class.cache_key_for(id)
    end
  end

  module DevelopmentMethods
    def self.included(base)
      base.extend ClassMethods
      base.send(:include, InstanceMethods)
      base.send(:after_initialize, :cache_record_for_development)
    end

    module ClassMethods
      def auto_cache_enabled?
        AUTO_CACHE_MODELS == true ||
          (AUTO_CACHE_MODELS.is_a?(Array) && AUTO_CACHE_MODELS.include?(self.name))
      end
    end

    module InstanceMethods
      def cache_record_for_development
        begin
          if self.class.auto_cache_enabled?
            if self.respond_to?(:cache)
              if self.persisted?
                Rails.logger.debug "AUTO_CACHE #{self.class.name}:#{self.id} is getting cached"
                self.cache
              else
                Rails.logger.debug "AUTO_CACHE #{self.class.name} is not persisted"
              end
            else
              Rails.logger.debug "AUTO_CACHE #{self.class.name}:#{self.id} is not cacheable"
            end
          else
            Rails.logger.debug "AUTO_CACHE #{self.class.name}:#{self.id} is being skipped"
          end
        rescue => e
          Rails.logger.debug "AUTO_CACHE #{self.class.name} skipped due to fatal error: #{e.message}"
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActsAsCacheable)

if Rails.env.development?
  if defined?(AUTO_CACHE_MODELS)
    Rails.logger.debug "AUTO_CACHE is enabled: #{AUTO_CACHE_MODELS.inspect}"
    ActiveRecord::Base.send(:include, ActsAsCacheable::DevelopmentMethods)
  else
    Rails.logger.debug "AUTO_CACHE is not enabled"
  end
end
