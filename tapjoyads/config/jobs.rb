require 'base64'

JobRunner::Gateway.define do |s|
  
  machine_type = `#{ENV['APP_ROOT']}/server/server_type.rb`
  
  if machine_type == 'jobs' || machine_type == 'test'
    s.add_job 'get_ad_network_data', :interval => 8.minutes    
    s.add_job 'campaign_stats', :interval => 10.seconds
    s.add_job 'yesterday_campaign_stats', :interval => 30.minutes
    
    # SQS Queues:
    s.add_job 'conversion_tracking_queue', :interval => 2.seconds
    s.add_job 'rate_offer_queue', :interval => 5.seconds
    s.add_job 'failed_sdb_saves_queue', :interval => 2.seconds
    s.add_job 'cleanup_web_requests', :interval => 5.minutes
    s.add_job 'cleanup_store_click', :interval => 5.minutes
    s.add_job 'create_offers', :interval => 5.seconds
    s.add_job 'create_rewarded_installs', :interval => 5.seconds
    s.add_job 'send_money_txn', :interval => 5.seconds
    s.add_job 'queue_send_currency', :interval => 5.seconds
    s.add_job 'queue_failed_downloads', :interval => 20.seconds
    s.add_job 'queue_app_stats', :interval => 60.seconds
    s.add_job 'queue_reward_aggregator', :interval => 5.seconds
    s.add_job 'queue_pre_create_domains', :interval => 1.minutes
    # s.add_job 'queue_import_udids', :interval => 10.seconds
    s.add_job 'queue_calculate_show_rate', :interval => 20.seconds
    s.add_job 'queue_calculate_next_payout', :interval => 5.minutes
  elsif machine_type == 'masterjobs'
    s.add_job 'master_cleanup_web_requests', :daily => 5.hours
    s.add_job 'master_create_offers', :interval => 1.minutes
    #s.add_job 'master_app_stats', :interval => 2.minutes
    s.add_job 'master_reward_aggregator', :hourly => 5.minutes
    s.add_job 'master_pre_create_domains', :daily => 6.hours
    s.add_job 'master_calculate_show_rate', :interval => 40.minutes
    s.add_job 'master_failed_sqs_writes', :interval => 3.minutes
    s.add_job 'master_reload_statz', :interval => 10.minutes
    s.add_job 'master_calculate_next_payout', :daily => 4.hours
  else
    Rails.logger.info "JobRunner: Not running any jobs. Not a job server."
  end
end