class OneOffs
  def self.unfix_offer_discounts
    offers = Offer.scoped(:conditions => "item_type not in ('App', 'ActionOffer') and payment < bid").find_each do |offer|
      offer.update_payment!
    end
  end
end
