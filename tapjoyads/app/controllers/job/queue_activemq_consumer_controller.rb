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
      tmp_path = "tmp/#{filename}.s3"
      s3_path  = "#{params[:queue]}/#{now.to_s(:yyyy_mm_dd)}/#{now.hour}/#{filename}"
      data     = File.open(tmp_path, 'w+')
      
      messages.each do |msg|
        data.puts(msg.body)
      end
      
      retries = 3
      begin
        data.rewind
        bucket = S3.bucket(BucketNames::ACTIVEMQ_MESSAGES)
        bucket.put(s3_path, data.read)
      rescue Exception => e
        if retries > 0
          retries -= 1
          sleep(1)
          retry
        else
          consumer.close
          data.close
          File.delete(tmp_path)
          raise e
        end
      end
      
      data.close
      File.delete(tmp_path)
      
      messages.each do |msg|
        consumer.acknowledge(msg)
      end
    end
    
    consumer.close
    
    render :text => 'ok'
  end
  
end
