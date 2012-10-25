class OneOffs
  def self.add_cached_offer_list_domain
    CachedOfferList.delete_domain('cached_offer_lists')
    CachedOfferList.create_domain('cached_offer_lists')
    #create s3 bucket
    S3.create_bucket(BucketNames::CACHED_OFFER_LIST)
  end
end
