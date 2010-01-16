class DeviceAppList < SimpledbResource

  def dynamic_domain_name
    return  "device_app_list_1"
    
    # TODO: enable this code after re-balancing.
    # # We need to lookup the domain number for this device from the device_lookup domain.
    # lookup = DeviceLookup.new(:key => @key)
    # domain_number = lookup.get('app_list')
    # 
    # if domain_number.nil?
    #  # This is a new device, so add it to the DeviceLookup table.
    #  domain_number = rand(MAX_DEVICE_APP_DOMAINS) 
    #  lookup.put('app_list', domain_number)
    #  lookup.save(:updated_at => false)
    # end
    # 
    # return  "device_app_list_#{domain_number}"
  end
  
  ##
  # Sets the last run time for app_id to now, potentially adding a new app if it's the first run.
  def set_app_ran(app_id)
    # TODO: If this device already has too many attributes, shard it accross multiple rows.
    put('app.' + app_id,  Time.now.utc.to_f.to_s)
  end
  
  ##
  # Returns true if we have seen this device run app_id.
  def has_app(app_id)
    return !get('app.' + app_id).nil?
  end
  
  ##
  # Returns the last time this device has run app_id. Returns nil if the device has not run app_id.
  def last_run_time(app_id)
    last_run_timestamp = get('app.' + app_id)
    if last_run_timestamp.nil?
      return nil
    else
      return Time.at(last_run_timestamp.to_f)
    end
  end
  
  ##
  # Returns an array of all app_id's that this device has been known to run.
  def get_app_list
    app_list = []
    @attributes.each do |attr|
      if attr[0] =~ /^app/
        app_list.push(attr[0].split('.')[1])
      end
    end
    return app_list
  end
end