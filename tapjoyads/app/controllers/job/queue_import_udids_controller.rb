class Job::QueueImportUdidsController < Job::SqsReaderController
  def initialize
    super QueueNames::IMPORT_UDIDS
  end
  
  private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    
    app_key= json['app_key']
    udid_list = json['udid_list']
    
    dal_items = []
    
    udid_list.each do |udid|
      dal = DeviceAppList.new(:key => udid)
      dal.set_app_ran(app_key)
    
      if dal.is_new
        dal_items.push(dal)
        if dal_items.length == 25
          batch_put_new_devices(dal_items)
          dal_items.clear
        end
      else
        # Don't add to FailedSdbSaves queue on error. Keep errors in this queue.
        dal.serial_save(:catch_exceptions => false)
      end
    end
    
    batch_put_new_devices(dal_items)
  end
  
  def batch_put_new_devices(dal_items)
    domain_number = rand(MAX_DEVICE_APP_DOMAINS)
    lookup_items = []
    fixed_dal_items = []

    # Fix the domain name, so that they are all the same.
    domain_name = "device_app_list_#{domain_number}"

    dal_items.each do |item|
      fixed_dal_item = DeviceAppList.new({
        :domain_name => domain_name,
        :key => item.key,
        :attributes => item.attributes,
        :attrs_to_replace => item.attributes,
        :load => false
      })
      fixed_dal_items.push(fixed_dal_item)

      lookup = DeviceLookup.new(:key => item.key, :load => false)
      lookup.put('app_list', domain_number)
      lookup_items.push(lookup)
    end

    # Write to memcache.
    fixed_dal_items.each do |item|
      item.is_new = false
      item.save(:write_to_sdb => false)
    end
    lookup_items.each do |item|
      item.save(:write_to_sdb => false)
    end

    # Now batch_put the items to sdb
    SimpledbResource.put_items(fixed_dal_items)
    SimpledbResource.put_items(lookup_items)
  end
end