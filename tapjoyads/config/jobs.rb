require 'base64'

JobRunner::Gateway.define do |s|
  
  machine_type = `/home/webuser/server/server_type.rb`
  
  if machine_type == 'jobs' || machine_type == 'test'
    s.add_job 'get_ad_network_data', 8.minutes
  
    s.add_job 'app_stats', 30.seconds
    s.add_job 'yesterday_app_stats', 30.minutes
  
    s.add_job 'campaign_stats', 10.seconds
    s.add_job 'yesterday_campaign_stats', 30.minutes
  
    s.add_job 'fix_nils', 60.minutes
  elsif machine_type == 'master'
    
  else
    puts "Not running any jobs. Not a job server."
  end
  
  # Maintenance jobs. Run on all servers:
  
  # Memcache servers are hard-coded. Register-servers does not need to run.
  # s.add_job 'register_servers', 30.minutes
end