class Job::QueueEncodedWebRequestsController < Job::JobController
  
  def initialize
    @queue     = Sqs.queue(QueueNames::ENCODED_WEB_REQUESTS)
    @num_reads = 35 - [ @queue.size_not_visible / 10000, 10 ].min * 2
  end
  
  def index
    now                 = Time.zone.now
    available_messages  = []
    items_by_date       = {}
    message_by_item_key = {}
    
    Rails.logger.info "QueueEncodedWebRequests: num_reads = #{@num_reads}"
    
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
        uuid   = UUIDTools::UUID.random_create.to_s
        bucket = S3.bucket(BucketNames::FAILED_WEB_REQUEST_SAVES)
        bucket.put("parser_errors/#{uuid}", sdb_string)
        delete_message(message)
        Rails.logger.info "QueueEncodedWebRequests: ParserError, message logged to S3 as #{uuid}"
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
        
        retries = 1
        begin
          Timeout.timeout(7) { SimpledbResource.put_items(sdb_items) }
          Rails.logger.info "QueueEncodedWebRequests: Saved #{sdb_items.size} items to #{domain_name}"
        rescue RightAws::AwsError => e
          Mc.increment_count("failed_sdb_saves.batch_puts.#{(now.to_f / 1.hour).to_i}", false, 1.day)
          Rails.logger.info "QueueEncodedWebRequests: Failed saving #{sdb_items.size} items to #{domain_name} - #{e.class}: #{e.message}"
          Notifier.alert_new_relic(e.class, e.message, request, params) unless e.message =~ /ServiceUnavailable/
          if e.message =~ /SignatureDoesNotMatch/
            sdb_items.each do |item|
              begin
                item.save!
                delete_message(message_by_item_key[item.key])
              rescue Exception => e
                if e.message =~ /SignatureDoesNotMatch/
                  uuid   = UUIDTools::UUID.random_create.to_s
                  bucket = S3.bucket(BucketNames::FAILED_WEB_REQUEST_SAVES)
                  bucket.put("signature_does_not_match/#{uuid}", item.serialize)
                  delete_message(message_by_item_key[item.key])
                  Rails.logger.info "QueueEncodedWebRequests: SignatureDoesNotMatch, message logged to S3 as #{uuid}"
                end
              end
            end
          end
          next
        rescue Timeout::Error => e
          if retries > 0
            retries -= 1
            retry
          end
          Rails.logger.info "QueueEncodedWebRequests: Failed saving #{sdb_items.size} items to #{domain_name}"
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
