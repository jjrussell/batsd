class Job::SqsReaderController < Job::JobController

  def initialize(queue_name)
    @queue_name           = queue_name
    @short_queue_name     = @queue_name.split('/').last
    @num_reads            = 100
    @raise_on_error       = true
    @break_on_nil_message = true
  end

  def index
    queue      = Sqs.queue(@queue_name)
    visibility = queue.visibility_timeout
    count      = 0

    while count < @num_reads do
      count += 1

      message = queue.receive_message

      if message.nil?
        @break_on_nil_message ? break : next
      end

      Rails.logger.info "#{@short_queue_name} message received: #{message.body}"

      begin
        Mc.cache.add(get_memcache_lock_key(message.body), 'locked', visibility)
      rescue Memcached::NotStored => e
        Rails.logger.info('Lock exists for this message. Skipping processing.')
        next
      end

      begin
        on_message(message)
      rescue Exception => e
        Rails.logger.error("SqsReaderError (#{@short_queue_name}): #{e.class} - #{e.message}, message: #{message.body}")
        if @raise_on_error
          NewRelic::Agent.add_custom_parameters(split_message_into_params(message.body))
          raise e
        else
          next
        end
      end

      message.delete
    end

    render :text => 'ok'
  end

  def run_job
    message = AWS::SQS::ReceivedMessage.new(nil, nil, nil, { :body => params[:message] })
    on_message(message)

    render :text => 'ok'
  end

  private

  def get_memcache_lock_key(message_body)
    "sqslocks.#{@short_queue_name}.#{message_body.hash}.#{Time.now.to_i / 5.minutes}"
  end

  # NewRelic truncates parameter length to ~250 chars so split the message up
  def split_message_into_params(message_body)
    message_params = {}
    message_body.scan(/.{1,250}/).each_with_index do |val, i|
      message_params["message_#{i}"] = val
    end
    message_params
  end

end
