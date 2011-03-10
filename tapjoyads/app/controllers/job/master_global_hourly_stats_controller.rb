class Job::MasterGlobalHourlyStatsController < Job::JobController

  def index
    GlobalStats.aggregate_hourly_global_stats
    render :text => 'ok'
  end
end
