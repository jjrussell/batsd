# This job will group hourly stats into aggregate totals by partner/platform and
# global/platform. The stats are persisted to SimpleDB.

class Job::MasterGroupHourlyStatsController < Job::JobController

  def index
    StatsAggregation.aggregate_hourly_group_stats
    render :text => 'ok'
  end
end
