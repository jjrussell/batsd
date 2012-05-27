class Job::InternalCacheOptimizedOffersController < Job::JobController  
  
  def index
    unless Mc.distributed_get(job_key)
      OptimizedOfferList.cache_all
      Mc.distributed_put(job_key, "running", false, 15.minutes)
    end

    render :text => 'ok'
  end

  private

  def job_key
    self.class.name
  end

end
