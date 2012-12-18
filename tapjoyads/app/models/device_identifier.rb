class DeviceIdentifier < SimpledbShardedResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "device_identifiers", :read_from_riak => true

  # key_format: (hashed_udid | mac_address | sha1_hashed_raw_mac_address | android_id)
  #
  ALL_IDENTIFIERS = [
    :sha2_udid,
    :sha1_udid,
    :mac_address,
    :sha1_mac_address,
    :android_id,
  ]

  self.num_domains = NUM_DEVICE_IDENTIFIER_DOMAINS

  self.sdb_attr :udid

  def initialize(options = {})
    #Cache Device Identifiers
    super({ :load_from_memcache => true }.merge(options))
  end

  def save(options = {})
    super({ :write_to_memcache => true }.merge(options))
  end

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_DEVICE_IDENTIFIER_DOMAINS
    "device_identifiers_#{domain_number}"
  end

  def device_id
    get("device_id") || udid
  end

  def device_id=(device_id)
    put("device_id", device_id)
  end

  def self.find_device_for_identifier(identifier_name, consistent = true)
    identifier = nil
    identifier = DeviceIdentifier.find(identifier_name, :consistent => consistent) unless identifier_name.blank?
    return nil if identifier.nil? || identifier.device_id.to_s.start_with?('device_identifier')
    Device.find(identifier.device_id)
  end

  def self.find_device_from_params(params)
    device = nil
    [:tapjoy_device_id, :udid, :mac_address].each do |old_udid_style|
      device = Device.find(params[old_udid_style]) if params.include?(old_udid_style) && params[old_udid_style].present?
      break if device
    end
    if device.nil?
      params.slice(*ALL_IDENTIFIERS).each do |_, value|
        device = DeviceIdentifier.find_device_for_identifier(value)
        break if device
      end
    end
    device
  end
end

