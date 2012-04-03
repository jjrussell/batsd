class OneOffs
  def self.backfill_deeplink_offers
    #find and disable the manually-created deeplinks
    handmade = GenericOffer.find(:all).find_all { |go| go.url =~ /earn/ && go.name =~ /^Earn/ && go.primary_offer.tapjoy_enabled? }
    puts "Disabling #{handmade.count} manually-created deeplinks"
    handmade.each do |go|
      begin
        go.primary_offer.tapjoy_enabled = false
        go.primary_offer.save!
      rescue Exception
        nil
      end
    end

    #create the new ones
    puts "Creating new DeeplinkOffers..."
    count = 0
    Currency.all.each do |c|
      existing = DeeplinkOffer.find_by_currency_id(c.id)
      unless existing
        begin
          dl = DeeplinkOffer.new(:currency => c, :app => c.app, :partner => c.partner)
          dl.save!
          count += 1
        rescue Exception => e
          puts "Failed to create DeeplinkOffer for currency #{c.id}: #{e}"
        end
      end
    end
    puts "Created #{count} deeplink offers"
  end
end
