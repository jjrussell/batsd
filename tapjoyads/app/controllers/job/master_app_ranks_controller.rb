class Job::MasterAppRanksController < Job::JobController
  def initialize
    @now = Time.zone.now
  end
  
  def index
    StoreRank.populate_store_rankings(@now)

    render :text => 'ok'
  end
end