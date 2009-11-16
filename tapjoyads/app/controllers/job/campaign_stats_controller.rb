# Aggregates hourly stats for campaigns.

class Job::CampaignStatsController < Job::JobController
  include StatsJobHelper
  
  def index
    hourly_stats('campaign', Campaign)
    
    render :text => "ok"
  end
end