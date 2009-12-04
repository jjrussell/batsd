require 'base64'

JobRunner::Gateway.define do |s|
  
  machine_type = `server/server_type.rb`
  
  if machine_type == 'jobs' || machine_type == 'test'
    s.add_job 'get_ad_network_data', :interval => 8.minutes
  
    s.add_job 'fix_nils', :interval => 60.minutes
  
    s.add_job 'app_stats', :interval => 30.seconds
    s.add_job 'yesterday_app_stats', :interval => 30.minutes
  
    s.add_job 'campaign_stats', :interval => 10.seconds
    s.add_job 'yesterday_campaign_stats', :interval => 30.minutes
    
    # SQS Queues:
    s.add_job 'conversion_tracking_queue', :interval => 1.seconds
    s.add_job 'failed_sdb_saves_queue', :interval => 1.seconds
    s.add_job 'cleanup_web_requests', :interval => 1.minutes
  elsif machine_type == 'master'
    s.add_job 'master_cleanup_web_requests', :daily => 1.hours
  else
    puts "Not running any jobs. Not a job server."
  end
  
  # Maintenance jobs. Run on all servers:
  
  # Memcache servers are hard-coded. Register-servers does not need to run.
  # s.add_job 'register_servers', 30.minutes
end