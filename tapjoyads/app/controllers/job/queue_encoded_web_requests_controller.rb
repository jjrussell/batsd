class Job::QueueEncodedWebRequestsController < Job::JobController
  
  def initialize
    @queue     = Sqs.queue(QueueNames::ENCODED_WEB_REQUESTS)
    @num_reads = 5
  end
  
  def index
    now                 = Time.zone.now
    available_messages  = []
    items_by_date       = {}
    message_by_item_key = {}
    
    @num_reads.times do
      retries = 3
      begin
        additional_messages = @queue.receive_messages(10)
      rescue RightAws::AwsError => e
        if e.message =~ /^InternalError/ && retries > 0
          retries -= 1
          sleep(0.1)
          retry
        else
          raise e
        end
      end
      
      if additional_messages.empty?
        break
      else
        available_messages += additional_messages
      end
    end
    
    available_messages.each do |message|
      sdb_string = Base64::decode64(message.to_s)
      begin
        sdb_item = SimpledbResource.deserialize(sdb_string)
      rescue JSON::ParserError
        bucket = S3.bucket(BucketNames::FAILED_WEB_REQUEST_SAVES)
        bucket.put("parser_errors/#{UUIDTools::UUID.random_create.to_s}", sdb_string)
        delete_message(message)
        next
      end
      date = sdb_item.this_domain_name.scan(/^web-request-(\d{4}-\d{2}-\d{2})/)[0][0]
      items_by_date[date] ||= []
      items_by_date[date] << sdb_item
      message_by_item_key[sdb_item.key] = message
    end
    
    items_by_date.each do |date, items|
      items.each_slice(25) do |sdb_items|
        domain_name = "web-request-#{date}-#{rand(MAX_WEB_REQUEST_DOMAINS)}"
        sdb_items.each do |item|
          item.this_domain_name = domain_name
          item.put('from_queue', now.to_f.to_s)
        end
        
        Rails.logger.info "Saving #{sdb_items.size} items to #{domain_name}, keys: #{sdb_items.map(&:key).inspect}"
        
        retries = 1
        begin
          Timeout.timeout(15) { SimpledbResource.put_items(sdb_items) }
        rescue RightAws::AwsError => e
          Notifier.alert_new_relic(e.class, e.message, request, params)
          next
        rescue Timeout::Error => e
          if retries > 0
            retries -= 1
            retry
          end
          Notifier.alert_new_relic(e.class, e.message, request, params)
          next
        end
        
        sdb_items.each do |item|
          delete_message(message_by_item_key[item.key])
        end
      end
    end
    
    render :text => 'ok'
  end
  
private
  
  def delete_message(message)
    retries = 3
    begin
      message.delete
    rescue RightAws::AwsError => e
      if retries > 0
        retries -= 1
        sleep(0.1)
        retry
      else
        Rails.logger.info "Failed to delete SQS message: #{message.to_s}"
        Notifier.alert_new_relic(e.class, e.message, request, params)
      end
    end
  end
  
end
