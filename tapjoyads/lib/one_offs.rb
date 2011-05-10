class OneOffs
  
  def self.copy_instructions_into_offers
    ActionOffer.find_each do |action_offer|
      action_offer.primary_offer.update_attribute(:instructions, action_offer.instructions)
    end
  end

end
