class CachedOfferList < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "cached_offer_list"

  TYPES = %w(native optimized native-fallback)

  self.domain_name = 'cached_offer_lists'

  attr_accessor :offer_list
  self.sdb_attr :generated_at, :type => :time
  self.sdb_attr :cached_at, :type => :time
  self.sdb_attr :cached_offer_type
  self.sdb_attr :source
  self.sdb_attr :memcached_key

  def save(options = {})
    CachedOfferList::S3CachedOfferList.sync_cached_offer_list(self)
    super(options)
  end
end
