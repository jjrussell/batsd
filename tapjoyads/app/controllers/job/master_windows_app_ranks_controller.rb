class Job::MasterWindowsAppRanksController < Job::JobController
  def initialize
    @now = Time.zone.now
  end

  def index
    StoreRank.populate_windows_rankings(@now)

    render :text => 'ok'
  end
end
