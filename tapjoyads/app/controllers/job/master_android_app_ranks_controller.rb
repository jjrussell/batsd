class Job::MasterAndroidAppRanksController < Job::JobController
  def initialize
    @now = Time.zone.now
  end

  def index
    StoreRank.populate_android_market_rankings(@now)

    render :text => 'ok'
  end
end
