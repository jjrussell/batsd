class Job::SqsReaderController < Job::JobController

  def initialize(queue_name)
    @queue_name = queue_name
    @num_reads = 40
    @raise_on_error = true
  end

  def index
    retries = 2
    begin
      queue = Sqs.queue(@queue_name)
    rescue RightAws::AwsError => e
      Rails.logger.info "Error creating queue object: #{e}"
      if retries > 0
        Rails.logger.info "Retrying up to #{retries} more times."
        retries -= 1
        retry
      elsif e.message =~ /temporarily unavailable/
        error_count = Mc.increment_count(get_memcache_error_count_key, false, 10.minutes)
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
    
    @num_reads.times do
      # read a message off the queue
      retries = 3
      begin
        message = queue.receive
      rescue RightAws::AwsError => e
        if e.message =~ /^InternalError/ && retries > 0
          retries -= 1
          sleep(0.1)
          retry
        else
          raise e
        end
      end
      
      # the queue must be empty so stop looping
      break if message.nil?
      
      Rails.logger.info "#{@queue_name} message recieved: #{message.to_s}"
      params[:message] = message.to_s
      
      # try to lock the message to prevent multiple machines from operating on the same message
      begin
        Mc.cache.add(get_memcache_lock_key(message), 'locked', queue.visibility.to_i)
      rescue Memcached::NotStored => e
        Rails.logger.info('Lock exists for this message. Skipping processing.')
        next
      end
      
      # operate on the message
      begin
        on_message(message)
      rescue Exception => e
        Rails.logger.warn "Error processing message. Error: #{e}"
        if @raise_on_error
          add_custom_new_relic_params(message)
          raise e
        else
          NewRelic::Agent.agent.error_collector.notice_error(e, request, params[:action], params)
          next
        end
      end
      
      # delete the message
      retries = 3
      begin
        message.delete
      rescue RightAws::AwsError => e
        if e.message =~ /^ResourceUnavailable/ && retries > 0
          retries -= 1
          sleep(0.1)
          retry
        else
          add_custom_new_relic_params(message)
          raise e
        end
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
    "sqserrors.#{Socket.gethostname}.#{@queue_name}.#{Time.now.to_i / 5.minutes}"
  end
  
  def get_memcache_lock_key(message)
    "sqslocks.#{@queue_name}.#{message.hash}.#{Time.now.to_i / 5.minutes}"
  end
  
  # NewRelic truncates parameter length to ~250 chars so split the message up
  def add_custom_new_relic_params(message)
    if message.to_s.length > 250
      custom_params = {}
      message.to_s.scan(/.{1,250}/).each_with_index do |val, i|
        custom_params["message#{i}"] = val
      end
      NewRelic::Agent.add_custom_parameters(custom_params)
    end
  end
  
end