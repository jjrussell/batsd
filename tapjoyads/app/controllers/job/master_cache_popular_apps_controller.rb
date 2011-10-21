class Job::MasterCachePopularAppsController < Job::JobController

  def index
    PopularApp.cache

    render :text => 'ok'
  end

end
