class ProcessStoredIdsProcessor < ApplicationProcessor
  subscribes_to :process_stored_ids
  
  def on_message(message)
    start_time = Time.new
    Rails.logger.debug "ProcessStoredIds: Recieved message: #{message}"
    
    sdb = SDB::SDB.new(ENV['AMAZON_ACCESS_KEY_ID'], ENV['AMAZON_SECRET_ACCESS_KEY'])
    
    app_items_array = []
    lookup_item_array = []
    
    updated_at = Time.now.utc.to_f.to_s
    
    triplets = JSON.parse(message)
    devices = {}
    triplets.each do |triplet|
      device_id = triplet[0]
      app_id = triplet[1]
      timestamp = triplet[2]
      
      unless devices[device_id]
        devices[device_id] = []
      end
      
      devices[device_id].push([app_id, timestamp])
    end
    
    
    devices.each do |device_id, app_id_list|
      
      app_item_attribues = [SDB::Attribute.new('updated-at', updated_at, true)]
      app_id_list.each do |pair|
        app_id = pair[0]
        timestamp = pair[1]
        app_item_attribues.push(SDB::Attribute.new("app.#{app_id}", timestamp, true))
      end
      
      app_item = SDB::Item.new(device_id, app_item_attribues)
      lookup_item = SDB::Item.new(device_id, [SDB::Attribute.new('app_list', '1', true), SDB::Attribute.new('updated-at', updated_at, true)])
   
      app_items_array.push(app_item)
      lookup_item_array.push(lookup_item)
      
      if (app_items_array.length == 25)
        sdb.batch_put_attributes("#{RUN_MODE_PREFIX}device_app_list_1", app_items_array)
        sdb.batch_put_attributes("#{RUN_MODE_PREFIX}device_lookup", lookup_item_array)
        
        app_items_array = []
        lookup_item_array = []
      end
    end
    
    if (app_items_array.length > 0)
      sdb.batch_put_attributes("#{RUN_MODE_PREFIX}device_app_list_1", app_items_array)
      sdb.batch_put_attributes("#{RUN_MODE_PREFIX}device_lookup", lookup_item_array)
    end
    
    Rails.logger.info("ProcessStoredIds: Processed #{triplets.length} triplets (#{Time.now - start_time})")
  end
  
end