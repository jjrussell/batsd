class OneOffs
	def self.fix_offer_discounts
    count = 0

		Offer.find(:all, :include => :partner, :conditions => "partners.id = partner_id AND premier_discount > 0 AND payment != floor(bid*((100-partners.premier_discount)/100))").each { |o|      
      o.update_payment!
      count += 1
    }

    "Offers fixed: " + count.to_s
	end
end
