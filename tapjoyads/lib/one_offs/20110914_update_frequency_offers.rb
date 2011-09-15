class OneOffs
  def self.update_frequency_offers
    Offer.find_all_by_multi_complete(true).each do |offer|
      offer.frequency = Offer::FREQUENCIES['unlimited']
      offer.save!
    end
  end
end
