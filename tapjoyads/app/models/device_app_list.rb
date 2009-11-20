class DeviceAppList < SimpledbResource
  def initialize(key, load = true)
    # We need to lookup the domain number for this device, from the device_lookup domain.
    #lookup = DeviceLookup.new(key)
    #domain_number = lookup.get('app_list')

    #if domain_number.nil?
    #  # This is a new device, so add it to the next table
    #  domain_number = NEXT_DEVICE_APP_LIST_TABLE
    #  lookup.put('app_list', domain_number)
    #  lookup.save
    #end
    
    domain_number = 1 #todo: be smart with memcache
    
    domain = "device_app_list_#{domain_number}"   

    super domain, key, load
  end
  
  ##
  # Add an application to this device
  def add_app(app_id)
    unless get('app.' + app_id)
      put('app.' + app_id,  Time.now.utc.to_f.to_s)
    end
  end
end