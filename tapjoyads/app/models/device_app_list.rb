class DeviceAppList < SimpledbResource

  def dynamic_domain_name
    # We need to lookup the domain number for this device from the device_lookup domain.
    lookup = DeviceLookup.new(:key => @key)
    domain_number = lookup.get('app_list')

    if domain_number.nil?
      # For now, if it's not found, we assume it is in '1'. After rebalancing, we'll enable the below code.
      domain_number = 1
      # # This is a new device, so add it to the DeviceLookup table.
      # domain_number = rand(MAX_DEVICE_APP_DOMAINS) 
      # lookup.put('app_list', domain_number)
      # lookup.save
    end
    
    return  "device_app_list_#{domain_number}"
  end
  
  def save(options = {})
    if @is_new
      # Temporary. If this is a new item, place it in a random domain, and add to the lookup table.
      # After rebalancing is complete, this will be done in dynamic_domain_name.
      domain_number = rand(MAX_DEVICE_APP_DOMAINS)
      @this_domain_name = get_real_domain_name("device_app_list_#{domain_number}")
      
      lookup = DeviceLookup.new(:key => @key)
      lookup.put('app_list', domain_number)
      lookup.save
    end
    super(options)
  end
  
  ##
  # Sets the last run time for app_id to now, potentially adding a new app if it's the first run.
  # Returns a list of web-request paths that should be added. Potential paths are:
  # 'new_user', 'daily_user', 'monthly_user'.
  def set_app_ran(app_id)
    now = Time.now.utc
    
    path_list = []
    last_run_time_array = get("app.#{app_id}", :force_array => true)
    if last_run_time_array.empty?
      path_list.push('new_user')
      last_run_time_array.push('0')
    end
    last_run_time = Time.at(last_run_time_array.last.to_f).utc
    
    if now.year != last_run_time.year or now.yday != last_run_time.yday
      path_list.push('daily_user')
    end
    if now.year != last_run_time.year or now.month != last_run_time.month
      path_list.push('monthly_user')
    end
    
    # TODO: If this device already has too many attributes, shard it accross multiple rows.
    put("app.#{app_id}",  now.to_f.to_s)
    
    return path_list
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