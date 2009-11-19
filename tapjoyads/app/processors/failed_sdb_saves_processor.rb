class FailedSdbSaves < ApplicationProcessor
  
  subscribes_to :failed_sdb_saves
  
  def on_message(message)
    sdb_item = SimpledbResource.deserialize(message)
    sdb_item.put('from_queue', '1')
    sdb_item.save
  end
  
end