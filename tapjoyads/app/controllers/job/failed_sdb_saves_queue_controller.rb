class Job::FailedSdbSavesQueueController < Job::SqsReaderController
  def initialize
    super QueueNames::FAILED_SDB_SAVES
  end
  
  private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    
    s3 = RightAws::S3.new(nil, nil, :multi_thread => true)
    
    options = {}
    
    bucket = s3.bucket('failed-sdb-saves')
    
    begin
      sdb_string = bucket.get(json['uuid'])
    rescue RightAws::AwsError => e
      if e.message.starts_with?('NoSuchKey')
        # This will raise an error if the key is not found.
        bucket.get("complete/#{json['uuid']}")
        
        NewRelic::Agent.agent.error_collector.notice_error(
            Exception.new("Duplicate FailedSdbSaves read. Already operated on #{json['uuid']}.")
        return
      else
        raise e
      end
    end
    
    string_options = json['options']
    
    # Convert all keys to symbols, rather than strings.
    string_options.each do |key, value|
      options[key.to_sym] = value
    end
    
    sdb_item = SimpledbResource.deserialize(sdb_string)
    sdb_item.put('from_queue', Time.now.utc.to_f.to_s)
    sdb_item.serial_save(options.merge({:catch_exceptions => false}))
    
    bucket.move_key(json['uuid'], "complete/#{json['uuid']}")
  end
end