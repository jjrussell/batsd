class DailyCampaignStatsJob
  include StatsJobHelper
  
  def run
    daily_stats('campaign', Campaign)
  end
end