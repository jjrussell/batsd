JobRunner::Gateway.define do |s|
  s.add_job :get_ad_network_data, GetAdNetworkDataJob, 5.minutes
  
  s.add_job :app_stats, AppStatsJob, 12.seconds
  s.add_job :daily_app_stats, DailyAppStatsJob, 10.minutes
  
  s.add_job :campaign_stats, CampaignStatsJob, 12.seconds
  s.add_job :daily_campaign_stats, DailyCampaignStatsJob, 10.minutes
  
  s.add_job :fix_app_nils, FixAppNilsJob, 10.minutes
  
end