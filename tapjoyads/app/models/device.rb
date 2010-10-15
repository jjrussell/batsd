class Device < SimpledbResource
  
  # TO REMOVE - when all device_app_list domains have finished converting to devices domains
  attr_accessor :pulled_from_device_app_list
  # END TO REMOVE
  
  self.sdb_attr :apps, :type => :json, :default_value => {}
  
  def dynamic_domain_name
    domain_number = @key.hash % NUM_DEVICES_DOMAINS
    "devices_#{domain_number}"
  end
  
  def load(load_from_memcache = true)
    super(load_from_memcache)
    
    # TO REMOVE - when all device_app_list domains have finished converting to devices domains
    @pulled_from_device_app_list = false
    if @attributes.empty?
      device_app_list = DeviceAppList.new(:key => @key)
      unless device_app_list.new_record?
        @pulled_from_device_app_list = true
        self.apps = device_app_list.apps
      end
    end
    # END TO REMOVE
    
    @parsed_apps = apps
  end
  
  def set_app_ran(app_id)
    now = Time.zone.now
    
    path_list = []
    
    unless app_id =~ /^(\w|\.|-)*$/
      Notifier.alert_new_relic(InvalidAppIdForDeviceAppList, "udid: #{@key}, app_id: #{app_id}")
      return path_list
    end
    
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
    
    @parsed_apps[app_id] = now.to_f.to_s
    self.apps = @parsed_apps
    
    path_list
  end
  
  def has_app(app_id)
    last_run_time(app_id).present?
  end
  
  def last_run_time(app_id)
    last_run_timestamp = @parsed_apps[app_id]
    
    if last_run_timestamp.is_a?(Array)
      last_run_timestamp = last_run_timestamp[0]
    end
    
    last_run_timestamp.present? ? Time.zone.at(last_run_timestamp.to_f) : nil
  end
  
end
