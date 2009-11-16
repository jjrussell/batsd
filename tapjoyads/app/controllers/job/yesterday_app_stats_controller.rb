# Aggregates yesterday's hourly stats for apps.

class Job::YesterdayAppStatsController < Job::JobController
  include StatsJobHelper
  
  def index
    yesterday_hourly_stats('app', App)
    
    render :text => "ok"
  end
end