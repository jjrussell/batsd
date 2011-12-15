class DeviceIdentifier < SimpledbShardedResource
  # key_format: (hashed_udid | mac_address)

  self.num_domains = NUM_DEVICE_IDENTIFIERS_DOMAINS

  self.sdb_attr :udid

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_DEVICE_IDENTIFIERS_DOMAINS
    "device_identifiers_#{domain_number}"
  end

  def serial_save(options = {})
    unless self.udid.present?
      raise 'The identifier must have a UDID associated with it.' unless options[:catch_exceptions]
      return false
    end
    super(options)
  end
end

