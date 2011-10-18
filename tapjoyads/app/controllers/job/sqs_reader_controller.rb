class Job::SqsReaderController < Job::JobController

  def initialize(queue_name)
    @queue_name = queue_name
    @num_reads = 100
    @raise_on_error = true
    @break_on_nil_message = true
  end

  def index
    queue = Sqs.queue(@queue_name)
    
    count = 0
    while count < @num_reads do
      count += 1
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
      
      if message.nil?
        @break_on_nil_message ? break : next
      end
      
      Rails.logger.info "#{@queue_name} message received: #{message.to_s}"
      
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
        message_params = split_message_into_params(message.to_s)
        if @raise_on_error
          NewRelic::Agent.add_custom_parameters(message_params)
          raise e
        else
          unless e.is_a?(SkippedSendCurrency)
            NewRelic::Agent.agent.error_collector.notice_error(e, { :uri => request.path, :request_params => params.merge(message_params) })
          end
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
          message_params = split_message_into_params(message.to_s)
          NewRelic::Agent.add_custom_parameters(message_params)
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
  
  def get_memcache_lock_key(message)
    "sqslocks.#{@queue_name}.#{message.hash}.#{Time.now.to_i / 5.minutes}"
  end
  
  # NewRelic truncates parameter length to ~250 chars so split the message up
  def split_message_into_params(message)
    message_params = {}
    message.scan(/.{1,250}/).each_with_index do |val, i|
      message_params["message_#{i}"] = val
    end
    message_params
  end
  
end