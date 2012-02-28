class OneOffs
  def self.remove_featured_min_bid_overrides
    Offer.featured.free.apps.scoped(:conditions => 'min_bid_override < 65 and min_bid_override > 10').each do |o|
      o.min_bid_override = nil
      o.save!
    end
  end
end
