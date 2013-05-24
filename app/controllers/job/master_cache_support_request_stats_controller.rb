class Job::MasterCacheSupportRequestStatsController < Job::JobController

  def index
    SupportRequestStats.cache_all

    render :text => 'ok'
  end

end
