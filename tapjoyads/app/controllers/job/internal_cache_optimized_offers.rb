class Job::InternalCacheOptimizedOffers < Job::JobController

  def index
    OptimizedOfferList.cache_all
    render :text => 'ok'
  end

end
