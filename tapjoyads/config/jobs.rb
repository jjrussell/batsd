require 'base64'

JobRunner::Gateway.define do |s|
  
  unless ENV['RAILS_ENV'] == 'development'
    security_groups = Base64::decode64(`curl -s http://169.254.169.254/latest/meta-data/security-groups`).split("\n")
    if security_groups.include? 'testserver'
      machine_type = :jobs
    elsif security_groups.include? 'masterjobs'
      machine_type = :master
    else
      machine_type = :web
    end
  else
    machine_type = :jobs
  end
  
  if machine_type == :jobs
    s.add_job 'get_ad_network_data', 8.minutes
  
    s.add_job 'app_stats', 30.seconds
    s.add_job 'yesterday_app_stats', 30.minutes
  
    s.add_job 'campaign_stats', 10.seconds
    s.add_job 'yesterday_campaign_stats', 30.minutes
  
    s.add_job 'fix_nils', 60.minutes
  elsif machine_type == :master
    
  end
  
  # Maintenance jobs. Run on all servers:
  
  # Memcache servers are hard-coded. Register-servers does not need to run.
  # s.add_job 'register_servers', 30.minutes
end