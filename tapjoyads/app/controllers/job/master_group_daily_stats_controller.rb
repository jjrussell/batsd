# This job will group daily stats into aggregate totals by partner/platform and
# global/platform. It will not run until every offer has had its daily stats
# aggregated for the previous UTC day, after which it will process that entire
# day's stats.

class Job::MasterGroupDailyStatsController < Job::JobController

  def index
    lockfile = "tmp/daily_group_stats.lock"
    unless File.exists?(lockfile)
      `touch #{lockfile}`
      begin
        StatsAggregation.aggregate_daily_group_stats
      rescue Exception => e
        File.delete(lockfile)
        raise e
      end
      File.delete(lockfile)
    end

    render :text => 'ok'
  end
end
