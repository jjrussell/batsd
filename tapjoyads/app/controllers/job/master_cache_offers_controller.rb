class Job::MasterCacheOffersController < Job::JobController
  
  def index
    Offer.enabled_offers.find_each do |offer|
      offer.update_attribute(:show_rate, 0.10) if offer.is_free? && offer.show_rate > 0.10 && offer.partner.balance <= 10000
    end
    
    Offer.cache_offer_stats
    Offer.cache_offers
    
    # Currency.tapjoy_enabled.find_each do |currency|
    #   Sqs.send_message(QueueNames::CACHE_OFFERS, currency.id)
    # end
    
    render :text => 'ok'
  end
  
end
