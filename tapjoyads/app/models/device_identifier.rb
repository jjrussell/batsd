class DeviceIdentifier < SimpledbShardedResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "device_identifiers"

  # key_format: (hashed_udid | mac_address | sha1_hashed_raw_mac_address | open_udid | idfa | android_id)
  #
  ALL_IDENTIFIERS = [
    :sha2_udid,
    :sha1_udid,
    :mac_address,
    :sha1_mac_address,
    :open_udid,
    :android_id,
    :idfa,
  ]

  self.num_domains = NUM_DEVICE_IDENTIFIER_DOMAINS

  self.sdb_attr :udid

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_DEVICE_IDENTIFIER_DOMAINS
    "device_identifiers_#{domain_number}"
  end

end

