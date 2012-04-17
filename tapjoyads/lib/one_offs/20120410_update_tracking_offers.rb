class OneOffs
  def self.update_tracking_offers
    Offer.scoped(:conditions => "tracking_for_id is not null").find_each do |offer|
      offer.update_attribute :tapjoy_enabled, true
    end
  end
end
