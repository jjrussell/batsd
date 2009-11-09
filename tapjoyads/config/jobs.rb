JobRunner::Gateway.define do |s|
  s.add_job :get_ad_network_data, GetAdNetworkDataJob, 5.minutes
  s.add_job :app_stats, AppStatsJob, 12.seconds
 
end