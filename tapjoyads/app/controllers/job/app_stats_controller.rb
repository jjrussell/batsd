# Aggregates hourly stats for apps.

class Job::AppStatsController < Job::JobController
  include StatsJobHelper
  
  def index
    hourly_stats('app', App)
    
    render :text => "ok"
  end
end