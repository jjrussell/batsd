#!/usr/bin/env ruby
require 'sdb/sdb'

# This script was originally in two files. The on_message method was in an activemessaging
# processor. Since we are no longer using activemessaging, the on_message method was
# moved to this file, so that the code could be preserved.

def on_message(message)
  start_time = Time.new
  Rails.logger.debug "ProcessStoredIds: Recieved message: #{message}"
  
  sdb = SDB::SDB.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
  
  app_items_array = []
  lookup_item_array = []
  
  updated_at = Time.now.utc.to_f.to_s
  
  pairs = JSON.parse(message)
  devices = {}
  pairs.each do |pair|
    device_id = pair[0]
    app_id = pair[1]
    timestamp = 0
    
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
  
  Rails.logger.info("ProcessStoredIds: Processed #{pairs.length} pairs (#{Time.now - start_time})")
end

arr = []
count = 0
messages = 0
bad = 0

name = ARGV.first
File.open(name, "r") do |file|
  while (line = file.gets) 
    begin
      udid = line
      app_id = 'f8751513-67f1-4273-8e4e-73b1e685e83d'

      set = [udid, app_id]
      arr.push(set)
      count += 1
      if count % 50
        message = arr.to_json
        publish :process_stored_ids, message
        arr = []
        messages += 1
        print "Count: #{count}"
      end
    rescue => e
      puts 'Bad_Line: ' + line + e
      bad += 1
    end
  end
end

if arr.length > 0
  message = arr.to_json
  om_message(message)
  messages += 1
  arr = []
end

print "Messages sent: #{messages}"
print "Bad lines: #{bad}"
