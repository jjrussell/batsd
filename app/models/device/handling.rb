module Device::Handling
  def handle_connect!(app_id, params)
    return [] unless app_id =~ APP_ID_FOR_DEVICES_REGEX

    now                 = Time.zone.now
    path_list           = []
    update_identifying_attributes(params)
    is_jailbroken_was   = is_jailbroken
    country_was         = country
    last_run_time_was   = last_run_time(app_id)

    if last_run_time_was.nil?
      path_list.push('new_user')
      last_run_time_was = Time.zone.at(0)
      # mark papaya new users as jailbroken
      self.is_jailbroken = true if app_id == 'e96062c5-45f0-43ba-ae8f-32bc71b72c99'
    end

    offset = RubyVersionIndependent.hash(@key) % 1.day
    adjusted_now = now - offset
    adjusted_lrt = last_run_time_was - offset
    if adjusted_now.year != adjusted_lrt.year || adjusted_now.yday != adjusted_lrt.yday
      path_list.push('daily_user')
    end
    if adjusted_now.year != adjusted_lrt.year || adjusted_now.month != adjusted_lrt.month
      path_list.push('monthly_user')
    end

    @parsed_apps[app_id] = "%.5f" % now.to_f
    self.apps = @parsed_apps

    # Make sure we store the current SDK version of this app on this device
    self.set_sdk_version(app_id, params[:library_version])
    self.set_jailbroken(params[:lad], app_id)
    self.set_country(params)

    if (last_run_time_tester? || is_jailbroken_was != is_jailbroken || country_was != country || path_list.include?('daily_user') || @create_device_identifiers)
      # Temporary change volume tracking, tracking running until 2012-10-31
      Mc.increment_count(Time.now.strftime("tempstats_device_jbchange_%Y%m%d"), false, 1.month) if is_jailbroken_was != is_jailbroken
      save
      update_alternative_devices!(app_id)
    end

    path_list
  end

  def update_identifying_attributes(params)
    # TODO(isingh): DRY this up
    if params[:lookedup_udid].present? && params[:lookedup_udid].udid? && !self.udid.udid?
      self.udid = params[:lookedup_udid]
    end

    if params[:mac_address].present? && params[:mac_address].mac_address? && !self.mac_address.mac_address?
      self.mac_address = params[:mac_address]
    end

    if params[:advertising_id] && params[:advertising_id].valid_advertising_id? && !self.advertising_id.valid_advertising_id?
      self.advertising_id = params[:advertising_id]
    end

    self.android_id = params[:android_id] if params[:android_id].present?
  end

  def advertising_attributes
    [self.normalized_advertising_id, self.upgraded_idfa].uniq.compact
  end

  def standard_attributes
    [self.udid, self.mac_address].uniq.compact
  end

  def normalized_advertising_id
    DeviceService.normalize_advertising_id(self.advertising_id)
  end

  def update_alternative_devices!(app_id)
    self.alternative_device_ids.each do |alt_device_id|
      alt_device = Device.find(alt_device_id)
      next unless alt_device

      alt_device.set_last_run_time(app_id)

      if self.advertising_id_device?
        alt_device.advertising_id = self.advertising_id if self.advertising_id?
      else
        alt_device.udid = self.udid if self.udid?
        alt_device.mac_address = self.mac_address if self.mac_address?
      end

      alt_device.save
    end
  end

  def set_jailbroken(lad, app_id)
    if lad.present?
      if lad == '0'
        self.is_jailbroken = false
      else
        self.is_jailbroken = true unless app_id == 'f4398199-6316-4680-9acf-d6dbf7f8104a' # Feed Al has inaccurate jailbroken detection
      end
    end
  end

  def set_country(params)
    if params[:country].present?
      if self.country.present? && self.country != params[:country]
        Notifier.alert_new_relic(DeviceCountryChanged, "Country for udid: #{@key} changed from #{self.country} to #{params[:country]}", nil, params)
      end
      self.country = params[:country]
    end
  end

  def recreate_identifiers!(forced_recreate = false)
    device_ids_for_merge = mergeable_devices(forced_recreate)
    create_identifiers!
    copy_devices!(device_ids_for_merge, forced_recreate)
  end

  def load_historical_data!
    return unless advertising_id_device?
    return if self.idfa_processed

    self.idfa_processed = true
    device_ids_for_merge = mergeable_devices
    copy_devices!(device_ids_for_merge, false, true)
    save! if self.changed?
  end

  def create_identifiers!
    all_identifiers = available_identifiers
    all_identifiers.each do |identifier|
      device_identifier = DeviceIdentifier.new(:key => identifier)
      next if device_identifier.udid == key
      log_identifier_overwrite(device_identifier) if overwriting_identifier?(device_identifier)
      device_identifier.udid = key
      device_identifier.save!
    end
    merge_temporary_devices!(all_identifiers)
  end

  def duplicate_device_ids
    duplicates = available_identifiers.inject([]) do |duplicates, identifier|
      device_identifier = DeviceIdentifier.find(identifier)
      duplicates << device_identifier.udid if device_identifier && device_identifier.udid != key
      duplicates
    end
    duplicates.uniq
  end

  def copy_devices!(device_ids, copy_clicks = false, upgrade_advertising_id = false)
    device_ids.each do |device_id|
      copy_device!(device_id, copy_clicks, upgrade_advertising_id)
    end
  end

  def click_key(currency_id)
    "#{key}.#{currency_id}"
  end

  def has_upgraded_idfa_device?
    self.upgraded_idfa.present?
  end

  def set_upgraded_idfa!(device_id)
    self.upgraded_idfa = device_id
    save!
  end

  def set_upgraded_device_id(device_id)
    unless has_upgraded_device_id?(device_id)
      self.upgraded_device_id += [device_id]
      self.idfa_processed = true
    end
  end

  private

  def mac_address_mergeable?
    !(mac_address.nil? || key == mac_address || mac_address == "null" || key == "null")
  end

  def overwriting_identifier?(device_identifier)
    !device_identifier.new_record? && device_identifier.udid? && device_identifier.udid != key
  end

  def available_identifiers
    all_identifiers = [ Digest::SHA2.hexdigest(key), Digest::SHA1.hexdigest(key) ]

    all_identifiers.push(Digest::SHA2.hexdigest(udid)) if self.udid.present?
    all_identifiers.push(android_id) if self.android_id.present?

    if self.mac_address.present?
      all_identifiers.push(mac_address)
      all_identifiers.push(Digest::SHA1.hexdigest(Device.formatted_mac_address(mac_address)))
    end

    all_identifiers.uniq
  end

  def mergeable_devices(is_recreate = false)
    device_ids_for_merge = []
    device_ids_for_merge.concat(duplicate_device_ids) if is_recreate
    device_ids_for_merge.concat([self.udid, self.mac_address])
    device_ids_for_merge.uniq.compact.reject { |device_id| self.upgraded_device_id.include?(device_id) }
  end

  def copy_device!(device_id_for_copy, copy_clicks = false, upgrade_advertising_id = false)
    return unless device_id_mergeable?(device_id_for_copy)
    self.set_upgraded_device_id(device_id_for_copy) if self.advertising_id_device?
    device_for_copy = Device.find(device_id_for_copy)
    return unless device_for_copy
    return if upgrade_advertising_id && device_for_copy.has_upgraded_idfa_device? && !self.upgraded_device_id_changed?

    device_for_copy.parsed_apps.keys.each do |app_id|
      copy_for_currency!(app_id, Click.find(device_for_copy.click_key(app_id))) if copy_clicks
      copy_point_purchases!(app_id, device_for_copy)
    end
    self.apps = device_for_copy.parsed_apps.merge(@parsed_apps)
    self.publisher_user_ids = device_for_copy.publisher_user_ids.merge(publisher_user_ids)

    save!
    device_for_copy.set_upgraded_idfa!(self.key) if upgrade_advertising_id
  end

  def device_id_mergeable?(device_id_for_copy)
    !(device_id_for_copy.nil? ||
      key == device_id_for_copy ||
      device_id_for_copy == "null" ||
      key == "null")
  end

  def copy_point_purchases!(app_id, device_for_copy)
    currency_id = Currency.find_in_cache(app_id).try(:id)
    return unless currency_id.present?
    copy_for_currency!(currency_id, PointPurchases.new(:key => device_for_copy.click_key(currency_id)))
  end

  def copy_for_currency!(currency_id, original)
    original.copy!(click_key(currency_id)) if currency_id && original && !original.new_record?
  end

  def log_identifier_overwrite(device_identifier)
    WebRequest.new(:time => Time.zone.now).tap do |wr|
      wr.path                           = "device_identifier_overwrite"
      wr.app_id                         = last_app_run
      wr.udid                           = key
      wr.device_identifier              = device_identifier.key
      wr.new_udid_for_device_identifier = key
      wr.old_udid_for_device_identifier = device_identifier.udid
      wr.save
    end
  end

  def merge_temporary_devices!(all_identifiers)
    orig_apps = self.parsed_apps.clone
    all_identifiers.each do |identifier|
      temp_device = TemporaryDevice.find(identifier)
      if temp_device
        @parsed_apps.merge!(temp_device.apps)
        self.publisher_user_ids = temp_device.publisher_user_ids.merge(publisher_user_ids)
        self.display_multipliers = temp_device.display_multipliers.merge(display_multipliers)
        temp_device.delete_all
      end
    end
    self.apps = @parsed_apps

    save!(:create_identifiers => false) unless orig_apps == self.parsed_apps
  end

  def load_data_from_temporary_device
    temp_device = TemporaryDevice.new(:key => self.key)
    @parsed_apps = temp_device.apps.merge(self.parsed_apps)
    self.publisher_user_ids = temp_device.publisher_user_ids.merge(self.publisher_user_ids)
    self.display_multipliers = temp_device.display_multipliers.merge(self.display_multipliers)
    self.apps = @parsed_apps
  end
end
