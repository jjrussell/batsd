class TemporaryDevice < SimpledbShardedResource
  include RiakMirror
  #Note the that domain name is "td" to save on bytes since device keys are in memory for Riak  
  mirror_configuration :riak_bucket_name => "td"

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
