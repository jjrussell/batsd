class AppStatsJob
  include StatsJobHelper
  
  def run
    hourly_stats('app', App)
  end
end