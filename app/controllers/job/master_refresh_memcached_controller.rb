class Job::MasterRefreshMemcachedController < Job::JobController

  def index
    Mc.cache_all

    render :text => "ok"
  end

end
