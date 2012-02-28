class OneOffs
  def self.force_update_offers
    count = 0
    App.find_each(:joins => :app_metadata_mappings) do |app|
      count += app.offers.count + app.action_offers.count + (app.rating_offer ? 1 : 0)
      app.update_offers
      app.update_rating_offer if app.rating_offer.present?
      app.update_action_offers
    end
    puts "Processed #{count} offers"
  end
end
