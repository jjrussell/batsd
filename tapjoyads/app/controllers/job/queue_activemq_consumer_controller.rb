class Job::QueueActivemqConsumerController < Job::JobController
  
  def index
    now = Time.zone.now
    messages = []
    consumer = Activemq.get_consumer(params[:server], params[:queue]) do |message|
      messages << message
    end
    
    consumer.join(params[:seconds].to_f)
    consumer.listener_thread.exit
    
    unless messages.empty?
      data = messages.map { |msg| msg.body }.join("\n")
      path = "#{params[:queue]}/#{now.to_s(:yyyy_mm_dd)}/#{now.hour}/#{params[:server]}_#{UUIDTools::UUID.random_create.hexdigest}"
      
      retries = 3
      begin
        bucket = S3.bucket(BucketNames::ACTIVEMQ_MESSAGES)
        Timeout.timeout(60) { bucket.put(path, data) }
      rescue Exception => e
        if retries > 0
          retries -= 1
          sleep(1)
          retry
        else
          consumer.close
          raise e
        end
      end
      
      messages.each do |msg|
        consumer.acknowledge(msg)
      end
    end
    
    consumer.close
    
    render :text => 'ok'
  end
  
end
