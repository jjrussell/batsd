class Job::FailedSdbSavesQueueController < Job::SqsReaderController
  def initialize
    super QueueNames::FAILED_SDB_SAVES
  end
  
  private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    
    options = {}
    sdb_string = json['sdb']
    string_options = json['options']
    
    # Convert all keys to symbols, rather than strings.
    string_options.each do |key, value|
      options[key.to_sym] = value
    end
    
    sdb_item = SimpledbResource.deserialize(sdb_string)
    
    # Temporary hack to flush out corrupt messages.
    if sdb_item.get('name') == 'TORI'
      return
    end
    
    sdb_item.put('from_queue', '1')
    sdb_item.save(options)
  end
  
end