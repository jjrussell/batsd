class Job::MasterCacheOffersController < Job::JobController
  
  def index
    Offer.enabled_offers.each do |offer|
      if offer.partner.balance <= 10000 && offer.is_free? && offer.item_type != 'RatingOffer'
        new_show_rate = [ 0.10, offer.show_rate ].min
        offer.update_attribute(:show_rate, new_show_rate)
      end
    end
    
    S3.reset_connection
    
    Offer.cache_enabled_offers
    Offer.cache_classic_offers
    Offer.cache_featured_offers
    
    render :text => 'ok'
  end
  
end
