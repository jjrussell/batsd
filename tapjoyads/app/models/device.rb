class Device < SimpledbShardedResource
  self.num_domains = NUM_DEVICES_DOMAINS
  
  self.sdb_attr :apps, :type => :json, :default_value => {}
  self.sdb_attr :is_jailbroken, :type => :bool, :default_value => false
  self.sdb_attr :country
  
  def dynamic_domain_name
    domain_number = @key.hash % NUM_DEVICES_DOMAINS
    "devices_#{domain_number}"
  end
  
  def after_initialize
    @parsed_apps = apps
  end
  
  def set_app_ran(app_id, params)
    now = Time.zone.now
    
    path_list = []
    
    unless app_id =~ /^(\w|\.|-)*$/
      Notifier.alert_new_relic(InvalidAppIdForDevices, "udid: #{@key}, app_id: #{app_id}")
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
    
    if params[:lad].present?
      if params[:lad] == '0'
        Notifier.alert_new_relic(DeviceNoLongerJailbroken) if self.is_jailbroken
      else
        self.is_jailbroken = true
      end
    end
    
    if params[:country].present?
      if self.country.present? && self.country != params[:country]
        Notifier.alert_new_relic(DeviceCountryChanged, "Country for udid: #{@key} changed from #{self.country} to #{params[:country]}")
      end
      self.country = params[:country]
    end
    
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
