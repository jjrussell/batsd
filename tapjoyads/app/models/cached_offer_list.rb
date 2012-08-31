class CachedOfferList < SimpledbShardedResource
  TYPES = %w(native optimized native-fallback)
  self.num_domains = NUM_CACHED_OFFER_LIST_DOMAINS

  self.sdb_attr :generated_at, :type => :time
  self.sdb_attr :cached_at, :type => :time
  self.sdb_attr :cached_offer_type
  self.sdb_attr :source
  self.sdb_attr :memcached_key
  self.sdb_attr :offer_list, :type => :json #my thinking is that this would be good for a multi-dimensional array

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_CACHED_OFFER_LIST_DOMAINS
    "cached_offer_list_#{domain_number}"
  end
end
