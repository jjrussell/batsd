class DailyAppStatsJob
  include StatsJobHelper
  
  def run
    daily_stats('app', App)
  end
end