class OneOffs

  def self.backfill_non_rewarded_promo_links
    failed = []
    count = 0
    DeeplinkOffer.find_each do |deeplink|
      offer = deeplink.primary_offer
      if offer && deeplink.currency && !deeplink.currency.rewarded?
        puts "(\# #{count}) Attempting to modify offer #{deeplink.id}..."

        offer.user_enabled = false
        if offer.changed?
          count += 1
          unless offer.save
            puts "#{deeplink.id} failed to save! Continuing..."
            failed << deeplink.id
          end
        end

      end
    end

    puts "#{count - failed.length} non-rewarded promo links disabled successfully, #{failed.length} failed."
    unless failed.empty?
      puts "The following offer ID's weren't able to be saved:"
      failed.each { |failed_offer| puts failed_offer.id }
    end

  end

end
