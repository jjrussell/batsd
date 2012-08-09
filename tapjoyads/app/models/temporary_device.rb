class TemporaryDevice < SimpledbShardedResource
  self.num_domains = NUM_TEMPORARY_DEVICE_DOMAINS

  self.sdb_attr :apps, :type => :json, :default_value => {}
  self.sdb_attr :publisher_user_ids, :type => :json, :default_value => {}, :cgi_escape => true
  self.sdb_attr :display_multipliers, :type => :json, :default_value => {}, :cgi_escape => true

  def dynamic_domain_name
     domain_number = @key.matz_silly_hash % NUM_TEMPORARY_DEVICE_DOMAINS
    "temporary_devices_#{domain_number}"
  end

  def initialize(options = {})
    super({ :load_from_memcache => true }.merge(options))
  end
end
