class OneOffs
  def self.remove_min_bid_overrides_from_android_featured
    Offer.free.apps.scoped(:conditions => "min_bid_override >= 10 and platform != 'iphone'", :joins => :app).each do |o|
      o.min_bid_override = nil
      o.save!
    end
  end
end
