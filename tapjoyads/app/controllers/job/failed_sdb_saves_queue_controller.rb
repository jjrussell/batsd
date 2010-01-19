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
    sdb_string = bucket.get(json['uuid'])
    string_options = json['options']
    
    # Convert all keys to symbols, rather than strings.
    string_options.each do |key, value|
      options[key.to_sym] = value
    end
    
    sdb_item = SimpledbResource.deserialize(sdb_string)
    sdb_item.put('from_queue', Time.now.utc.to_f.to_s)
    sdb_item.save(options)
    
    bucket.delete_folder(json['uuid'])
  end
end