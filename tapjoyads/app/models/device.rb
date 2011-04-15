class Device < SimpledbShardedResource
  self.num_domains = NUM_DEVICES_DOMAINS
  
  attr_reader :parsed_apps
  
  self.sdb_attr :apps, :type => :json, :default_value => {}
  self.sdb_attr :is_jailbroken, :type => :bool, :default_value => false
  self.sdb_attr :country
  self.sdb_attr :internal_notes
  self.sdb_attr :survey_answers, :type => :json, :default_value => {}, :cgi_escape => true
  self.sdb_attr :opted_out, :type => :bool, :default_value => false
  self.sdb_attr :last_run_time_tester, :type => :bool, :default_value => false
  
  def dynamic_domain_name
    domain_number = @key.hash % NUM_DEVICES_DOMAINS
    "devices_#{domain_number}"
  end
  
  def after_initialize
    @parsed_apps = apps
  end
  
  def set_app_ran!(app_id, params)
    now = Time.zone.now
    path_list = []
    
    is_jailbroken_was = is_jailbroken
    country_was = country
    last_run_time_was = last_run_time(app_id)
    
    unless app_id =~ /^(\w|\.|-)*$/
      Notifier.alert_new_relic(InvalidAppIdForDevices, "udid: #{@key}, app_id: #{app_id}", nil, params)
      return path_list
    end
    
    if last_run_time_was.nil?
      path_list.push('new_user')
      last_run_time_was = Time.zone.at(0)

      # mark papaya new users as jailbroken
      if app_id == 'e96062c5-45f0-43ba-ae8f-32bc71b72c99'
        self.is_jailbroken = true
      end
    end
    
    if now.year != last_run_time_was.year || now.yday != last_run_time_was.yday
      path_list.push('daily_user')
    end
    if now.year != last_run_time_was.year || now.month != last_run_time_was.month
      path_list.push('monthly_user')
    end
    
    @parsed_apps[app_id] = "%.5f" % now.to_f
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
    
    if (last_run_time_tester? || is_jailbroken_was != is_jailbroken || country_was != country || path_list.include?('daily_user'))
      save
      Mc.increment_count("sdb_saves.devices_0.#{(now.to_f / 1.hour).to_i}", false, 1.day) if this_domain_name == 'devices_0'
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
