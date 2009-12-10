class Job::FailedSdbSavesQueueController < Job::SqsReaderController
  def initialize
    super QueueNames::FAILED_SDB_SAVES
  end
  
  private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    
    sdb_string = message.to_s
    options = {}
    if (json['sdb'])
      sdb_string = json['sdb']
      string_options = json['options']
      
      # Convert all keys to symbols, rather than strings.
      string_options.each do |key, value|
        options[key.to_sym] = value
      end
    end
    
    sdb_item = SimpledbResource.deserialize(sdb_string)
    sdb_item.put('from_queue', '1')
    sdb_item.save(options)
  end
  
end