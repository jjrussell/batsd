class DeviceIdentifier < SimpledbShardedResource
  # key_format: (hashed_udid | mac_address)

  self.num_domains = NUM_DEVICE_IDENTIFIER_DOMAINS

  self.sdb_attr :udid

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_DEVICE_IDENTIFIER_DOMAINS
    "device_identifiers_#{domain_number}"
  end

  def initialize(options = {})
    super({ :load_from_memcache => false }.merge(options))
  end

  def serial_save(options = {})
    super({ :write_to_memcache => false }.merge(options))
  end

end

