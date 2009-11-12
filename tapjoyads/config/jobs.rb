JobRunner::Gateway.define do |s|
  s.add_job :get_ad_network_data, GetAdNetworkDataJob, 8.minutes
  
  s.add_job :app_stats, AppStatsJob, 30.seconds
  s.add_job :daily_app_stats, DailyAppStatsJob, 30.minutes
  
  s.add_job :campaign_stats, CampaignStatsJob, 10.seconds
  s.add_job :daily_campaign_stats, DailyCampaignStatsJob, 30.minutes
  
  s.add_job :fix_app_nils, FixAppNilsJob, 60.minutes
  
  s.add_job :register_servers, RegisterServersJob, 5.minutes
end