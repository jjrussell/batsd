class OneOffs
  def self.fix_action_offer_icon_ids
    ActionOffer.all.each do |action_offer|
      action_offer.offers.each do |offer|
        offer.icon_id_override = offer.app_metadata_id if offer.icon_id_override == action_offer.app_id
        offer.save! if offer.icon_id_override_changed?
      end
    end
  end
end
