class OneOffs
  def self.move_use_raw_url_to_offers
    App.find_all_by_use_raw_url(true).each do |app|
      app.offers.each do |offer|
        offer.update_attributes!(:url_overridden => true)
      end
      app.action_offers.each do |action_offer|
        action_offer.offers.each do |offer|
          offer.update_attributes!(:url_overridden => true)
        end
      end
      if app.rating_offer
        app.rating_offer.offers.each do |offer|
          offer.update_attributes!(:url_overridden => true)
        end
      end
    end
    nil
  end
end