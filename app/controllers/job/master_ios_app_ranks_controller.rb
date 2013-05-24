class Job::MasterIosAppRanksController < Job::JobController
  def initialize
    @now = Time.zone.now
  end

  def index
    StoreRank.populate_itunes_appstore_rankings(@now)

    render :text => 'ok'
  end
end
