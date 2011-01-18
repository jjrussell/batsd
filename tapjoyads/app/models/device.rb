class Device < SimpledbShardedResource
  self.num_domains = NUM_DEVICES_DOMAINS
  
  self.sdb_attr :apps, :type => :json, :default_value => {}
  self.sdb_attr :is_jailbroken, :type => :bool, :default_value => false
  self.sdb_attr :country
  self.sdb_attr :internal_notes
  self.sdb_attr :survey_answers, :type => :json, :default_value => {}, :cgi_escape => true
  self.sdb_attr :opted_out, :type => :bool, :default_value => false
  
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
      Notifier.alert_new_relic(InvalidAppIdForDevices, "udid: #{@key}, app_id: #{app_id}", nil, params)
      return path_list
    end
    
    old_time = last_run_time(app_id)
    if old_time.nil?
      path_list.push('new_user')
      old_time = Time.zone.at(0)

      # mark papaya new users as jailbroken
      if (params[:app_id] == 'e96062c5-45f0-43ba-ae8f-32bc71b72c99' || params[:app_id] == 'cf6b4573-0efb-44a8-813d-26e248b81713')
        self.is_jailbroken = true
      end

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
        Notifier.alert_new_relic(DeviceNoLongerJailbroken, "device_id: #{@key}", nil, params) if self.is_jailbroken
        self.is_jailbroken = false
      else
        self.is_jailbroken = true unless app_id == 'f4398199-6316-4680-9acf-d6dbf7f8104a' # Feed Al has inaccurate jailbroken detection
      end
    end
    
    if params[:country].present?
      if self.country.present? && self.country != params[:country]
        Notifier.alert_new_relic(DeviceCountryChanged, "Country for udid: #{@key} changed from #{self.country} to #{params[:country]}", nil, params)
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
  
  def unset_app_ran!(app_id)
    @parsed_apps.delete(app_id)
    self.apps = @parsed_apps
    save!
  end
  
end
