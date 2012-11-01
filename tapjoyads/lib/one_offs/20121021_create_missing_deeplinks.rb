# OneOffs.create_missing_deeplinks
class OneOffs

  def self.create_missing_deeplinks
    query = 'currencies.id IN (SELECT currencies.id FROM currencies LEFT OUTER JOIN deeplink_offers ON ' <<
      'deeplink_offers.currency_id = currencies.id WHERE deeplink_offers.id IS NULL)'
    currencies = Currency.where(query).includes(:app, :partner)

    puts "# of currencies missing deeplinks: #{currencies.size}"
    puts

    currencies.each do |c|
      c.send(:create_deeplink_offer)
      if c.save && c.enabled_deeplink_offer_id == c.deeplink_offer.id
        puts "Deeplink offer successfully created for currency: #{c.id}"
      else
        puts "Deeplink offer not created / unsuccessfully linked to currency.enabled_deeplink_offer_id: #{c.id}"
      end
    end

    puts
    puts "NEW # of currencies missing deeplinks: #{Currency.where(query).size}"
    puts

    count = 0
    Currency.where('enabled_deeplink_offer_id IS NULL').includes(:deeplink_offer => :primary_offer).each do |c|
      if c.deeplink_offer.primary_offer.accepting_clicks?
        puts "Correcting enabled_deeplink_offer_id value for currency: #{c.id}"
        c.update_attributes!(:enabled_deeplink_offer_id => c.deeplink_offer.id)
        count += 1
      end
    end

    puts
    puts "# of CORRECTED enabled_deeplink_offer_id values: #{count}"
  end

end
