class OneOffs
	def self.fix_offer_discounts
		bad_offers = Offer.find(:all, :include => :partner, :conditions => "partners.id = partner_id AND bid > 1 AND premier_discount > 0 AND payment != floor(bid*((100-partners.premier_discount)/100))")

        bad_offers.each { |o| o.update_payment! }

        "Offers fixed: " << bad_offers.count.to_s
	end
end
