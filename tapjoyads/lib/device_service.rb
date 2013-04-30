class DeviceService
  class << self
    def ignored_udid?(udid)
      IGNORED_UDIDS.include?(udid)
    end

    def ignored_advertising_id?(advertising_id)
      IGNORED_ADVERTISING_IDS.include?(advertising_id)
    end

    def normalize_mac_address(mac_address)
      mac_address.downcase.gsub(/:/,"") if mac_address.present?
    end

    def normalize_advertising_id(advertising_id)
      advertising_id.downcase.gsub(/-/,"") if advertising_id.present?
    end
  end
end

require 'device_service/locator'
