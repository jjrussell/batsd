JobRunner::Gateway.define do |s|
  
  machine_type = `#{ENV['APP_ROOT']}/server/server_type.rb`
  
  if machine_type == 'jobs' || machine_type == 'test'
    s.add_job 'get_ad_network_data', :interval => 8.minutes    
    s.add_job 'campaign_stats', :interval => 10.seconds
    s.add_job 'yesterday_campaign_stats', :interval => 30.minutes
    
    # SQS Queues:
    s.add_job 'conversion_tracking_queue', :interval => 2.seconds
    s.add_job 'failed_sdb_saves_queue', :interval => 5.seconds
    s.add_job 'send_money_txn', :interval => 2.seconds
    s.add_job 'queue_send_currency', :interval => 2.seconds
    s.add_job 'queue_failed_downloads', :interval => 20.seconds
    s.add_job 'queue_app_stats', :interval => 30.seconds
    s.add_job 'queue_pre_create_domains', :interval => 1.minutes
    s.add_job 'queue_calculate_show_rate', :interval => 20.seconds
    s.add_job 'queue_select_vg_items', :interval => 5.seconds
    s.add_job 'queue_get_store_info', :interval => 5.minutes
    s.add_job 'queue_update_monthly_account', :interval => 1.minute
    s.add_job 'queue_grab_advertiser_udids', :interval => 5.minutes
    s.add_job 'queue_sdb_backups', :interval => 1.minute
    s.add_job 'queue_mail_chimp_updates', :interval => 1.minute
  elsif machine_type == 'masterjobs'
    # jobs with high impact on overall system performance
    s.add_job 'master_calculate_next_payout', :daily => 4.hours
    s.add_job 'master_grab_advertiser_udids', :daily => 7.hours
    s.add_job 'master_update_monthly_account', :daily => 8.hours
    s.add_job 'master_verifications', :daily => 5.hours
    
    # jobs with moderate impact on overall system performance
    s.add_job 'master_app_stats', :interval => 2.minutes
    s.add_job 'master_calculate_show_rate', :interval => 20.minutes
    s.add_job 'master_reload_money', :interval => 10.minutes
    s.add_job 'master_reload_money/daily', :daily => 10.minutes
    s.add_job 'master_reload_statz', :interval => 10.minutes
    s.add_job 'master_reload_statz/daily', :daily => 10.minutes
    
    # jobs with low impact on overall system performance
    s.add_job 'master_cache_offers', :interval => 1.minute
    s.add_job 'master_cleanup_web_requests', :daily => 5.hours
    s.add_job 'master_failed_sqs_writes', :interval => 3.minutes
    s.add_job 'master_get_store_info', :daily => 7.hours
    s.add_job 'master_grab_disabled_popular_offers', :daily => 8.hours
    s.add_job 'master_pre_create_domains', :daily => 6.hours
    s.add_job 'master_select_vg_items', :interval => 5.minutes
    s.add_job 'master_set_bad_domains', :interval => 1.minutes
  else
    Rails.logger.info "JobRunner: Not running any jobs. Not a job server."
  end
  
end
