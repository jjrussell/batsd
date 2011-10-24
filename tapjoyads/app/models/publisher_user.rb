class PublisherUser < SimpledbShardedResource
  MAX_UDIDS = 5

  self.num_domains = NUM_PUBLISHER_USER_DOMAINS

  self.sdb_attr :udids, :force_array => true, :replace => false

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_PUBLISHER_USER_DOMAINS
    "publisher_users_#{domain_number}"
  end

  def update!(udid)
    return false if udids.length >= MAX_UDIDS
    return true  if udids.include?(udid)

    self.udids = udid
    serial_save

    udids.length < MAX_UDIDS
  end

end
