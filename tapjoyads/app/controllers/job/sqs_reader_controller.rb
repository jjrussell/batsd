class Job::SqsReaderController < Job::JobController
  include RightAws
  include MemcachedHelper
  include NewRelicHelper

  def initialize(queue_name)
    @queue_name = queue_name
  end

  def index
    retries = 2
    begin
      queue = SqsGen2.new.queue(@queue_name)
    rescue AwsError => e
      Rails.logger.info "Error creating queue object: #{e}"
      if retries > 0
        Rails.logger.info "Retrying up to #{retries} more times."
        retries -= 1
        retry
      elsif e.message =~ /temporarily unavailable/
        error_count = increment_count_in_cache(get_memcache_error_count_key, false, 10.minutes)
        Rails.logger.info "SQS temporarily unavailable. Incrementing 5-minute count in memcache to: #{error_count}"
        if error_count > 20
          raise e
        end
        render :text => 'queue temporarily unavailable'
        return
      else
        raise e
      end
    end
    
    message = queue.receive
    unless message.nil?
      Rails.logger.info "#{@queue_name} message recieved: #{message.to_s}"
      params[:message] = message.to_s
      
      begin
        CACHE.add(get_memcache_lock_key(message), 'locked', queue.visibility.to_i)
        begin
          on_message(message)
          message.delete
        rescue Exception => e
          Rails.logger.warn "Error processing message. Error: #{e}"
          raise e
        end
      rescue Memcached::NotStored => e
        alert_new_relic(SqsLockExistsError, 'Lock exists for this message. Skipping processing.',
            request, params)
      end
    end
    
    render :text => 'ok'
  end

  def run_job
    on_message(params[:message])
    
    render :text => 'ok'
  end


  private
  
  ##
  # Returns a new key for every 5-minute window. The key is unique to this host and this queue.
  def get_memcache_error_count_key
    "sqserrors.#{Socket.gethostname}.#{@queue_name}.#{(Time.now.to_i / 5.minutes).to_i}"
  end
  
  def get_memcache_lock_key(message)
    "sqslocks.#{@queue_name}.#{message.hash}"
  end
end