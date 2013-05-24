# This job will group all partners' daily stat totals into global aggregate totals by platform.
# It processes the previous day's stats.

class Job::MasterGroupDailyStatsController < Job::JobController

  def index
    lockfile = "tmp/daily_group_stats.lock"
    unless File.exists?(lockfile)
      `touch #{lockfile}`
      begin
        StatsAggregation.aggregate_global_stats((Time.zone.now - 1.day).beginning_of_day, true)
      rescue Exception => e
        File.delete(lockfile)
        raise e
      end
      File.delete(lockfile)
    end

    render :text => 'ok'
  end
end
