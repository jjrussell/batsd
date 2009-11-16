require 'base64'

JobRunner::Gateway.define do |s|
  
  machine_type = Base64::decode64(`curl -s http://169.254.169.254/1.0/user-data`) if ENV['RAILS_ENV'] != "development"
  
  # Expensive jobs. Only run these on job servers.
  if machine_type == 'jobserver'
    s.add_job 'get_ad_network_data', 8.minutes
  
    s.add_job 'app_stats', 30.seconds
    s.add_job 'yesterday_app_stats', 30.minutes
  
    s.add_job 'campaign_stats', 10.seconds
    s.add_job 'yesterday_campaign_stats', 30.minutes
  
    s.add_job 'fix_app_nils', 60.minutes
  end
  
  # Maintenance jobs. Run on all servers:
  s.add_job 'register_servers', 30.minutes
end