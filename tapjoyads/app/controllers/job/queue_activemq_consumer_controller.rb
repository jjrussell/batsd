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
      filename = "#{params[:server]}_#{UUIDTools::UUID.random_create.hexdigest}"
      path = "#{params[:queue]}/#{now.to_s(:yyyy_mm_dd)}/#{now.hour}/#{filename}"
      data = File.open("tmp/#{filename}", 'w+')
      data.write(messages.map { |msg| msg.body }.join("\n"))
      
      retries = 3
      begin
        data.rewind
        bucket = S3.bucket(BucketNames::ACTIVEMQ_MESSAGES)
        bucket.put(path, data.read)
      rescue Exception => e
        if retries > 0
          retries -= 1
          sleep(1)
          retry
        else
          consumer.close
          data.close
          File.delete("tmp/#{filename}")
          raise e
        end
      end
      
      data.close
      File.delete("tmp/#{filename}")
      
      messages.each do |msg|
        consumer.acknowledge(msg)
      end
    end
    
    consumer.close
    
    render :text => 'ok'
  end
  
end
