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

    #render :text => 'ok'
  end
end
