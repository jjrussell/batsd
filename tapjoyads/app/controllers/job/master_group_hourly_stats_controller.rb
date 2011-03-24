class Job::MasterGroupHourlyStatsController < Job::JobController

  def index
    StatsAggregation.aggregate_hourly_group_stats
    render :text => 'ok'
  end
end
