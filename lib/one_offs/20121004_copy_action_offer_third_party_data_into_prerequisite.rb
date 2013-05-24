class OneOffs

  def self.copy_third_party_data
    ActionOffer.all.each do |action_offer|
      action_offer.offers.each do |offer|
        puts offer.name
        prerequisite_offer = Offer.find_by_id(offer.third_party_data)
        if prerequisite_offer.present? && offer.prerequisite_offer_id.blank?
          if prerequisite_offer.partner_id == offer.partner_id
            offer.prerequisite_offer_id = offer.third_party_data
          else
            offer.x_partner_prerequisites = (offer.get_x_partner_prerequisites << offer.third_party_data).to_a.join(';')
          end
        end
        offer.save! if offer.changed?
      end
    end
  end
end
