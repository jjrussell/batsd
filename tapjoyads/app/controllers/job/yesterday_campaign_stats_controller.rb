# Aggregates yesterday's stats for campaigns.

class Job::YesterdayCampaignStatsController < Job::JobController
  include StatsJobHelper
  
  def index
    yesterday_hourly_stats('campaign', Campaign)
    
    render :text => "ok"
  end
end