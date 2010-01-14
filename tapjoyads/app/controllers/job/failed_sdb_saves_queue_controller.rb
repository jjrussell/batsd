class Job::FailedSdbSavesQueueController < Job::SqsReaderController
  def initialize
    super QueueNames::FAILED_SDB_SAVES
  end
  
  private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    
    options = {}
    if json['sdb']
      sdb_string = json['sdb']
    else
      s3 = RightAws::S3.new(:multi_thread => true)
      bucket = s3.bucket('failed-sdb-saves')
      sdb_string = bucket.get(json['uuid'])
    end
    string_options = json['options']
    
    # Convert all keys to symbols, rather than strings.
    string_options.each do |key, value|
      options[key.to_sym] = value
    end
    
    sdb_item = SimpledbResource.deserialize(sdb_string)
    sdb_item.put('from_queue', Time.now.utc.to_f.to_s)
    sdb_item.save(options)
    
    if s3
      s3.delete_folder(json['uuid'])
    end
  end
  
end