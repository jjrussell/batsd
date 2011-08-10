class Job::QueueFailedWebRequestSavesController < Job::JobController
  
  def initialize
    @queue     = Sqs.queue(QueueNames::FAILED_WEB_REQUEST_SAVES)
    @bucket    = S3.bucket(BucketNames::FAILED_WEB_REQUEST_SAVES)
    @num_reads = 5
  end
  
  def index
    sleep(rand(10))
    available_messages = []
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
    
    items_by_date       = {}
    message_by_item_key = {}
    
    available_messages.each do |message|
      json            = JSON.parse(message.to_s)
      uuid            = json['uuid']
      incomplete_path = "incomplete/#{uuid}"
      complete_path   = "complete/#{uuid}"
      
      if @bucket.key(incomplete_path).exists?
        sdb_string = @bucket.get(incomplete_path)
        sdb_item = nil
        begin
          sdb_item = SimpledbResource.deserialize(sdb_string)
        rescue JSON::ParserError => e
          move_s3_key(uuid, 'parser_errors')
          delete_message(message)
          next
        end
        sdb_item.put('from_queue', Time.zone.now.to_f.to_s)
        date = sdb_item.this_domain_name.scan(/^web-request-(\d{4}-\d{2}-\d{2})/)[0][0]
        items_by_date[date] ||= []
        items_by_date[date] << sdb_item
        message_by_item_key[sdb_item.key] = message
      elsif @bucket.key(complete_path).exists?
        delete_message(message)
      else
        Notifier.alert_new_relic(SdbObjectNotInS3, "Serialized SDB object not found in S3. Need to retry saving #{uuid}.", request, params)
      end
    end
    
    if items_by_date.present?
      now          = Time.zone.now
      earlier      = now - 5.minutes
      hour_key     = ((now.day != earlier.day ? now : earlier).to_f / 1.hour).to_i
      error_counts = {}
    end
    items_by_date.each do |date, items|
      items.in_groups_of(25) do |sdb_items|
        sdb_items.compact!
        
        domain_name = ''
        20.times do
          domain_name = "web-request-#{date}-#{rand(MAX_WEB_REQUEST_DOMAINS)}"
          error_counts[date] ||= {}
          error_counts[date][domain_name] ||= Mc.get_count("failed_sdb_saves.sdb.#{domain_name}.#{hour_key}") { 0 }
          break if error_counts[date][domain_name] == 0
        end
        domain_name = error_counts[date].sort { |a, b| a[1] <=> b[1] }[0][0] if error_counts[date][domain_name] > 0
        sdb_items.each { |item| item.this_domain_name = domain_name }
        
        Rails.logger.info "Saving #{sdb_items.size} items to #{domain_name}, keys: #{sdb_items.map(&:key).inspect}"
        
        begin
          SimpledbResource.put_items(sdb_items)
        rescue RightAws::AwsError => e
          Notifier.alert_new_relic(e.class, e.message, request, params)
          next
        end
        
        sdb_items.each do |item|
          json = JSON.parse(message_by_item_key[item.key].to_s)
          uuid = json['uuid']
          move_s3_key(uuid, 'complete')
          delete_message(message_by_item_key[item.key])
        end
      end
    end
    
    render :text => 'ok'
  end
  
private
  
  def move_s3_key(uuid, destination)
    incomplete_path  = "incomplete/#{uuid}"
    destination_path = "#{destination}/#{uuid}"
    retries          = 3
    begin
      @bucket.move_key(incomplete_path, destination_path)
    rescue RightAws::AwsError => e
      if retries > 0
        retries -= 1
        sleep(0.1)
        retry
      else
        Rails.logger.info "Failed to move S3 key: from #{incomplete_path} to #{destination_path}"
        Notifier.alert_new_relic(e.class, e.message, request, params)
      end
    end
  end
  
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
