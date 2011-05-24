class Job::MasterFetchTopFreemiumAndroidAppsController < Job::JobController
  def initialize
  end

  def index
    StoreRank.populate_top_freemium_android_apps

    render :text => 'ok'
  end
end
