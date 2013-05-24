module Device::Sdk
  def handle_sdkless_click!(offer, now)
    if offer.sdkless?
      temp_sdkless_clicks = sdkless_clicks

      hash_key = offer.third_party_data
      if offer.get_platform == 'iOS'
        hash_key = offer.app_protocol_handler.present? ? offer.app_protocol_handler : "tjc#{offer.third_party_data}"
      end

      temp_sdkless_clicks[hash_key] = { 'click_time' => now.to_i, 'item_id' => offer.item_id }
      temp_sdkless_clicks.reject! { |key, value| value['click_time'] <= (now - 2.days).to_i }
      self.sdkless_clicks = temp_sdkless_clicks
      @retry_save_on_fail = true
      save
    end
  end

  def self.can_set_sdk?(version)
    version.present? && version.valid_version_string? && version.version_greater_than_or_equal_to?('1.0')
  end

  def set_sdk_version(app_id, version)
    return unless Device::Sdk.can_set_sdk?(version)
    retry_save_on_fail = true if self.apps_sdk_versions[app_id].nil?
    temp_sdk_versions = self.apps_sdk_versions
    temp_sdk_versions[app_id] = version
    self.apps_sdk_versions = temp_sdk_versions
  end

  def set_sdk_version!(app_id, version)
    set_sdk_version(app_id, version)
    save
  end

  def sdk_version(app_id)
    self.apps_sdk_versions[app_id]
  end

  def unset_sdk_version!(app_id)
    temp_sdk_versions = self.apps_sdk_versions
    old_sdk_version = temp_sdk_versions.delete(app_id)
    self.apps_sdk_versions = temp_sdk_versions
    save
    old_sdk_version
  end
end
