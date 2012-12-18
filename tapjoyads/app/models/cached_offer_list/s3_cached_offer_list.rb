class CachedOfferList::S3CachedOfferList < S3Resource
  self.bucket_name = BucketNames::CACHED_OFFER_LIST
  @@sync_columns = Set.new

  def self.attribute(attribute, options = {})
    @@sync_columns.add(attribute)
    super(attribute, options)
  end

  self.attribute :generated_at, :type => :time
  self.attribute :cached_at, :type => :time
  self.attribute :cached_offer_type
  self.attribute :source
  self.attribute :memcached_key
  self.attribute :offer_list, :type => :json

  def self.sync_cached_offer_list(cached_offer_list)
    return unless Rails.env.production?
    col = self.new(:id => cached_offer_list.id)
    @@sync_columns.each { |n| col.send("#{n}=", cached_offer_list.send(n))}
    col.save
  end
end
