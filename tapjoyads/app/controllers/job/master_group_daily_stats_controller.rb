class Job::MasterGroupDailyStatsController < Job::JobController

  def index
    StatsAggregation.aggregate_daily_group_stats
    render :text => 'ok'
  end
end
