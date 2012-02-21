class OneOffs
  def self.remove_featured_min_bid_overrides
    Offer.connection.execute("update offers as temp inner join action_offers on temp.item_id = action_offers.id inner join apps on action_offers.app_id = apps.id set temp.min_bid_override = null where apps.platform = 'iphone' and temp.min_bid_override < 35 and temp.min_bid_override >= 10")
    Offer.connection.execute("update offers as temp inner join action_offers on temp.item_id = action_offers.id inner join apps on action_offers.app_id = apps.id set temp.min_bid_override = null where apps.platform = 'android' and temp.min_bid_override < 25 and temp.min_bid_override >= 10")
  end
end
