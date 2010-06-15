class Job::MasterCacheOffersController < Job::JobController
  
  def index
    Offer.cache_enabled_offers
    Offer.cache_classic_offers
    
    render :text => 'ok'
  end
  
end
