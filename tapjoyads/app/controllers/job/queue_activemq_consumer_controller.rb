class Job::QueueActivemqConsumerController < Job::JobController
  
  def index
    now = Time.zone.now
    unacked_messages = []
    consumer = Activemq.get_consumer(params[:server], params[:queue]) do |message|
      unacked_messages << message
    end
    
    consumer.join(20)
    
    messages = unacked_messages.dup
    unacked_messages = []
    
    unless messages.empty?
      data = messages.map { |msg| msg.body }.join("\n")
      path = "#{params[:queue]}/#{now.to_s(:yyyy_mm_dd)}/#{now.hour}/#{params[:server]}_#{UUIDTools::UUID.random_create.hexdigest}"
      
      retries = 3
      begin
        bucket = S3.bucket(BucketNames::ACTIVEMQ_MESSAGES)
        bucket.put(path, data)
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
