class DeviceIdentifier < SimpledbShardedResource
  # key_format: (hashed_udid | mac_address | sha1_hashed_raw_mac_address | open_udid | advertiser_id | android_id)
  #
  ALL_IDENTIFIERS = [
    :sha2_udid,
    :sha1_udid,
    :mac_address,
    :sha1_mac_address,
    :open_udid,
    :android_id,
    :advertiser_id,
  ]

  self.num_domains = NUM_DEVICE_IDENTIFIER_DOMAINS

  self.sdb_attr :udid

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_DEVICE_IDENTIFIER_DOMAINS
    "device_identifiers_#{domain_number}"
  end

end

