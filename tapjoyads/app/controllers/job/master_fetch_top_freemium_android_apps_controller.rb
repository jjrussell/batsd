class Job::MasterFetchTopFreemiumAndroidAppsController < Job::JobController
  def initialize
  end

  def index
    StoreRank.top_freemium_android_apps

    render :text => 'ok'
  end
end
