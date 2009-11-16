class DeviceLookupProcessor < ApplicationProcessor
  
  subscribes_to :device_lookup
  
  def on_message(message)
    lookup = DeviceLookup.deserialize(message)
    lookup.put('from_queue', '1')
    lookup.save
  end
  
end