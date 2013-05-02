module FormatChecks
  UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
  UDID_REGEX = /^[a-f0-9]{40}$/

  def uuid?
    self =~ UUID_REGEX
  end

  def udid?
    self =~ UDID_REGEX
  end

  def valid_advertising_id?
    self.present? && self.length == 32 && self =~ /^\w+$/
  end

  def mac_address?
    self.present? && DeviceService.normalize_mac_address(self).length == 12
  end
end

class String
  include FormatChecks
end

class NilClass
  include FormatChecks
end
