class DeviceAppList < SimpledbResource

  self.sdb_attr :apps, :type => :json, :default_value => {}

  def dynamic_domain_name
    # We need to lookup the domain number for this device from the device_lookup domain.
    lookup = DeviceLookup.new(:key => @key)
    domain_number = lookup.get('app_list', :force_array => true)[0]

    if domain_number.nil?
      # This is a new device, so add it to the DeviceLookup table.
      domain_number = rand(MAX_DEVICE_APP_DOMAINS)
      
      lookup.put('app_list', domain_number)
      lookup.save
    end
    
    return  "device_app_list_#{domain_number}"
  end
  
  def load(load_from_memcache = true)
    super(load_from_memcache)
    
    if self.attributes['apps'].blank?
      convert_attributes
    end
    @parsed_apps = apps
  end
  
  ##
  # Sets the last run time for app_id to now, potentially adding a new app if it's the first run.
  # Returns a list of web-request paths that should be added. Potential paths are:
  # 'new_user', 'daily_user', 'monthly_user'.
  def set_app_ran(app_id)
    now = Time.now.utc
    
    path_list = []
    old_time = last_run_time(app_id)
    if old_time.nil?
      path_list.push('new_user')
      old_time = Time.zone.at(0)
    end
    
    if now.year != old_time.year || now.yday != old_time.yday
      path_list.push('daily_user')
    end
    if now.year != old_time.year || now.month != old_time.month
      path_list.push('monthly_user')
    end
    
    apps_hash = apps
    apps_hash[app_id] = now.to_f.to_s
    apps = apps_hash
    
    @parsed_apps = apps
    
    return path_list
  end
  
  ##
  # Returns true if we have seen this device run app_id.
  def has_app(app_id)
    return !last_run_time(app_id).nil?
  end
  
  ##
  # Returns the last time this device has run app_id. Returns nil if the device has not run app_id.
  def last_run_time(app_id)
    last_run_timestamp = @parsed_apps[app_id]
    
    if last_run_timestamp.is_a?(Array)
      last_run_timestamp = last_run_timestamp[0]
    end
    
    if last_run_timestamp.nil?
      return nil
    else
      return Time.at(last_run_timestamp.to_f)
    end
  end
  
  ##
  # Returns an array of all app_id's that this device has been known to run.
  def get_app_list
    return @parsed_apps.keys
  end
  
  ##
  # Converts attributes from old-style: (many app.<app_id> attributes) to new-style: (one 'apps' attribute,
  # which is a single json object).
  def convert_attributes
    return if @attributes.empty?
    
    apps_hash = {}
    @attributes.each do |attr_name, value|
      if attr_name =~ /^app/
        app_id = attr_name.split('.')[1]
        apps_hash[app_id] = self.get(attr_name, :force_array => true)[0]
        self.delete(attr_name)
      end
    end
    
    self.apps = apps_hash
  end
end