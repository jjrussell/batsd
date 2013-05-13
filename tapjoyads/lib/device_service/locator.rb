class DeviceService::Locator < DeviceService
  attr_accessor :params, :device_id, :lookup_via,
    :set_temporary_udid, :identifiers_provided
  OTHER_IDENTIFIERS = [:advertising_id, :mac_address]

  def initialize(input_params, set_temp_udid = false)
    self.params             = input_params
    self.device_id          = nil
    self.lookup_via         = nil
    self.set_temporary_udid = set_temp_udid

    from_params(set_temporary_udid) if params.present?
  end

  def from_params(set_temporary_udid)
    device_found(params[:advertising_id], :params) and return if params[:advertising_id].present?
    device_found(params[:udid], :params) and return if params[:udid].present?

    lookup_keys = available_lookup_keys
    self.identifiers_provided = lookup_keys.present?
    lookup_keys.each do |identifier_key|
      udid = device_id_from_identifier(identifier_key)
      device_found(udid, :lookup) and return if udid
    end

    OTHER_IDENTIFIERS.each do |other_identifier|
      device_found(params[other_identifier], :alternative_udid) and return if params[other_identifier].present?
    end

    device_found(lookup_keys.first, :temporary) and return if set_temporary_udid && lookup_keys.any?
    device_found(nil, :not_found)
  end

  def device_id_from_identifier(identifier)
    identifier = DeviceIdentifier.find(identifier)
    return nil if invalid_device_id?(identifier.try(:udid))
    identifier.udid
  end

  def device
    @device ||= Device.find(self.device_id)
  end

  def current_device
    Device.new({:key => self.device_id, :is_temporary => is_temporary?})
  end

  def has_lookup_keys?
    available_lookup_keys.any?
  end

  private

  def invalid_device_id?(device_key)
    device_key.nil? ||
      IGNORED_UDIDS.include?(device_key) ||
      IGNORED_ADVERTISING_IDS.include?(device_key) ||
      device_key.to_s.start_with?('device_identifier')
  end

  def device_found(device_key, found_by)
    @device         = nil
    self.device_id  = device_key
    self.lookup_via = found_by
  end

  def is_temporary?
    self.set_temporary_udid && self.lookup_via == :temporary
  end

  def available_lookup_keys
    DeviceIdentifier::ALL_IDENTIFIERS.inject([]) do |lookup_keys, identifier|
      lookup_keys.push(params[identifier]) if params[identifier].present?
      lookup_keys
    end
  end
end
