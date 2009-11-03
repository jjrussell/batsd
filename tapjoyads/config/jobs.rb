JobRunner::Gateway.define do |s|
  s.add_job :get_ad_network_data, GetAdNetworkDataJob, 5.minutes
 
end