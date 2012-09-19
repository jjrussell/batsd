class OneOffs
  def self.save_already_complete_ids_to_offers
    Offer::Rejecting::ALREADY_COMPLETE_IDS.each do |k, v|
      k.each do |offer_id|
        offer = Offer.find_by_id(offer_id)
        if offer.present?
          puts offer.name
          v.delete(offer_id)
          offer.x_partner_exclusion_prerequisites = offer.get_x_partner_exclusion_prerequisites.merge(v.to_set).to_a.join(';')
          offer.save! if offer.x_partner_exclusion_prerequisites_changed?
        else
          puts "offer id: #{offer_id} not found"
        end
      end
    end
  end
end
