class OneOffs
  def self.add_cached_offer_list_domain
    CachedOfferList.create_domain('cached_offer_lists')
  end
end
