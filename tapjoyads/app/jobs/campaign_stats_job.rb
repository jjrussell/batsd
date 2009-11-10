class CampaignStatsJob
  include StatsJobHelper
  
  def run
    hourly_stats('campaign', Campaign)
  end
end