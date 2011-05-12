class OneOffs
  
  def self.copy_instructions_into_offers
    ActionOffer.find_each do |action_offer|
      offer = action_offer.primary_offer
      offer.instructions = action_offer.instructions
      offer.url = action_offer.app.direct_store_url
      offer.save!
    end
  end

end
