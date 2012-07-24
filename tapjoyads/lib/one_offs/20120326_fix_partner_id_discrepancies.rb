class OneOffs
  def self.fix_partner_id_discrepancies
    counter = 0
    ActionOffer.find_each do |action_offer|
      unless action_offer.partner == action_offer.app.partner
        action_offer.update_attributes(:partner => action_offer.app.partner)
        counter += 1
      end
    end
    puts "Processed #{counter} action offers."
  end
end
