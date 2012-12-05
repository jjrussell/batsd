# This job will group hourly stats into global aggregate totals by platform.
# It collects the current day's stats from partner totals and persists the
# global numbers to SimpleDB.

class Job::MasterGroupHourlyStatsController < Job::JobController

  def index
    StatsAggregation.aggregate_global_stats
    render :text => 'ok'
  end
end
