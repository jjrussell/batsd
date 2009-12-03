class Job::FailedSdbSavesQueueController < Job::SqsReaderController
  def initialize
    super QueueNames::FAILED_SDB_SAVES
  end
  
  private
  
  def on_message(message)
    sdb_item = SimpledbResource.deserialize(message)
    sdb_item.put('from_queue', '1')
    sdb_item.save
  end
  
end