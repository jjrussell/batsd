class OneOffs
  def self.fix_action_offer_urls
    App.find_all_by_use_raw_url(true).each do |app|
      app.action_offers.each do |action_offer|
        action_offer.offers.each do |offer|
          offer.update_attributes!(:url => app.read_attribute(:store_url))
        end
      end
    end
    App.find_all_by_use_raw_url(false).each do |app|
      app.action_offers.each do |action_offer|
        action_offer.offers.each do |offer|
          offer.update_attributes!(:url => app.store_url)
        end
      end
    end
    nil
  end
end
