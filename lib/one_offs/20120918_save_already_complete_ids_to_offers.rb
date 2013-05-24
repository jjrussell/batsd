class OneOffs
  def self.save_already_complete_ids_to_offers
    Offer::Rejecting::ALREADY_COMPLETE_IDS.each do |k, v|
      k.each do |offer_id|
        offer = Offer.find_by_id(offer_id)
        if offer.present?
          puts offer.name
          complete_ids_set = Set.new
          v.each do |already_complete_id|
            next if already_complete_id == offer_id
            complete_ids_set.add(already_complete_id) if Offer.find_by_id(already_complete_id).present?
          end
          offer.x_partner_exclusion_prerequisites = offer.get_x_partner_exclusion_prerequisites.merge(complete_ids_set).to_a.join(';')
          offer.save! if offer.x_partner_exclusion_prerequisites_changed?
        else
          puts "offer id: #{offer_id} not found"
        end
      end
    end
  end
end
