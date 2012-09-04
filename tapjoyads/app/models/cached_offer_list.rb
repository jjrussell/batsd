class CachedOfferList < SimpledbResource
  TYPES = %w(native optimized native-fallback)
  self.domain_name = 'cached_offer_list'

  self.sdb_attr :generated_at, :type => :time
  self.sdb_attr :cached_at, :type => :time
  self.sdb_attr :cached_offer_type
  self.sdb_attr :source
  self.sdb_attr :memcached_key
  self.sdb_attr :offer_list, :type => :json #my thinking is that this would be good for a multi-dimensional array

end
