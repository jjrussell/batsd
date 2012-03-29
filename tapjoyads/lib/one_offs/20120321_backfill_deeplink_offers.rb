class OneOffs
  def self.backfill_deeplink_offers
    #find and disable the manually-created deeplinks
    handmade = GenericOffer.all.find { |go| go.url =~ /earn/ && go.name =~ '^Earn' }
    puts "Disabling #{handmade.count} manually-created deeplinks"
    handmade.each { |go|
      go.primary_offer.tapjoy_enabled = false
      go.primary_offer.save!
    }

    #create the new ones
    count = 0
    Currency.all.each do |c|
      dl = DeeplinkOffer.new(:currency => c, :app => c.app, :partner => c.partner)
      dl.save!
      count += 1
    end
    puts "Created #{count} deeplink offers"
  end
end
