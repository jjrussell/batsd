class AddAppToDeviceProcessor < ApplicationProcessor
  
  subscribes_to :add_app_to_device
  
  def on_message(message)
    lookup = DeviceAppList.deserialize(message)
    lookup.save
  end
  
end