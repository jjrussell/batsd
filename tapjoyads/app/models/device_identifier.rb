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
    :advertising_id,
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
    domain_number = RubyVersionIndependent.hash(@key) % NUM_DEVICE_IDENTIFIER_DOMAINS
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
end
