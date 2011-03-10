class Job::MasterGlobalDailyStatsController < Job::JobController

  def index
    GlobalStats.aggregate_daily_global_stats
    render :text => 'ok'
  end
end
