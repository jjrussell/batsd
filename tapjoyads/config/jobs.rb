require 'base64'

JobRunner::Gateway.define do |s|
  
  machine_type = Base64::decode64(`curl -s http://169.254.169.254/1.0/user-data`)
  
  # Expensive jobs. Only run these on job servers.
  if machine_type == 'jobserver'
    s.add_job :get_ad_network_data, GetAdNetworkDataJob, 8.minutes
  
    s.add_job :app_stats, AppStatsJob, 30.seconds
    s.add_job :daily_app_stats, DailyAppStatsJob, 30.minutes
  
    s.add_job :campaign_stats, CampaignStatsJob, 10.seconds
    s.add_job :daily_campaign_stats, DailyCampaignStatsJob, 30.minutes
  
    s.add_job :fix_app_nils, FixAppNilsJob, 60.minutes
  end
  
  # Maintenance jobs. Run on all servers:
  s.add_job :register_servers, RegisterServersJob, 1.minutes
end