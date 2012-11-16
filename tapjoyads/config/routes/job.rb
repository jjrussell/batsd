Tapjoyad::Application.routes.draw do
  namespace :job do
    match 'master_update_cloudwatch_rpm(/index)' => 'master_update_cloudwatch_rpm#index'
    match 'master_cache_optimized_offers(/index)' => 'master_cache_optimized_offers#index'
    match 'master_activate_editors_picks(/index)' => 'master_activate_editors_picks#index'
    match 'master_alerts(/index)' => 'master_alerts#index'
    match 'master_android_app_ranks(/index)' => 'master_android_app_ranks#index'
    match 'master_android_market_format(/index)' => 'master_android_market_format#index'
    match 'master_apple_epf(/index)' => 'master_apple_epf#index'
    match 'master_archive_conversions(/index)' => 'master_archive_conversions#index'
    match 'master_cache_offers(/index)' => 'master_cache_offers#index'
    match 'master_cache_popular_apps(/index)' => 'master_cache_popular_apps#index'
    match 'master_cache_recommendations(/index)' => 'master_cache_recommendations#index'
    match 'master_calculate_next_payout(/index)' => 'master_calculate_next_payout#index'
    match 'master_calculate_ranking_fields(/index)' => 'master_calculate_ranking_fields#index'
    match 'master_calculate_show_rate(/index)' => 'master_calculate_show_rate#index'
    match 'master_change_partners(/index)' => 'master_change_partners#index'
    match 'master_daily_app_stats(/index)' => 'master_daily_app_stats#index'
    match 'master_delete_gamers(/index)' => 'master_delete_gamers#index'
    match 'master_external_publishers/cache' => 'master_external_publishers#cache'
    match 'master_external_publishers/populate_potential' => 'master_external_publishers#populate_potential'
    match 'master_failed_sqs_writes(/index)' => 'master_failed_sqs_writes#index'
    match 'master_get_store_info(/index)' => 'master_get_store_info#index'
    match 'master_grab_disabled_popular_offers(/index)' => 'master_grab_disabled_popular_offers#index'
    match 'master_group_daily_stats(/index)' => 'master_group_daily_stats#index'
    match 'master_group_hourly_stats(/index)' => 'master_group_hourly_stats#index'
    match 'master_healthz(/index)' => 'master_healthz#index'
    match 'master_hourly_app_stats(/index)' => 'master_hourly_app_stats#index'
    match 'master_ios_app_ranks(/index)' => 'master_ios_app_ranks#index'
    match 'master_partner_notifications(/index)' => 'master_partner_notifications#index'
    match 'master_payout_info_reminders(/index)' => 'master_payout_info_reminders#index'
    match 'master_payout_info_reminders(/index)' => 'master_payout_info_reminders#index'
    match 'master_recreate_actions_from_rewards(/index)' => 'master_recreate_actions_from_rewards#index'
    match 'master_refresh_memcached(/index)' => 'master_refresh_memcached#index'
    match 'master_reload_money(/index)' => 'master_reload_money#index'
    match 'master_reload_statz(/index)' => 'master_reload_statz#index'
    match 'master_reload_statz/daily' => 'master_reload_statz#daily'
    match 'master_reload_statz/devices_count' => 'master_reload_statz#devices_count'
    match 'master_reload_statz/partner_daily' => 'master_reload_statz#partner_daily'
    match 'master_reload_statz/partner_index' => 'master_reload_statz#partner_index'
    match 'master_run_offer_events(/index)' => 'master_run_offer_events#index'
    match 'master_run_offer_events(/index)' => 'master_run_offer_events#index'
    match 'master_select_vg_items(/index)' => 'master_select_vg_items#index'
    match 'master_set_exclusivity_and_premier_discounts(/index)' => 'master_set_exclusivity_and_premier_discounts#index'
    match 'master_terminate_slow_instances(/index)' => 'master_terminate_slow_instances#index'
    match 'master_udid_reports(/index)' => 'master_udid_reports#index'
    match 'master_update_app_active_gamer_count(/index)' => 'master_update_app_active_gamer_count#index'
    match 'master_update_cloudwatch_as_stats(/index)' => 'master_update_cloudwatch_as_stats#index'
    match 'master_update_linkshare_clicks(/index)' => 'master_update_linkshare_clicks#index'
    match 'master_update_monthly_account(/index)' => 'master_update_monthly_account#index'
    match 'master_update_papaya_devices(/index)' => 'master_update_papaya_devices#index'
    match 'master_update_papaya_user_count(/index)' => 'master_update_papaya_user_count#index'
    match 'master_update_rev_share(/index)' => 'master_update_rev_share#index'
    match 'master_verifications(/index)' => 'master_verifications#index'
    match 'queue_cache_external_publishers(/index)' => 'queue_cache_external_publishers#index'
    match 'queue_calculate_show_rate(/index)' => 'queue_calculate_show_rate#index'
    match 'queue_change_partners(/index)' => 'queue_change_partners#index'
    match 'queue_conversion_tracking(/index)' => 'queue_conversion_tracking#index'
    match 'queue_conversion_tracking/run_job' => 'queue_conversion_tracking#run_job'
    match 'queue_create_conversions(/index)' => 'queue_create_conversions#index'
    match 'queue_create_conversions/run_job' => 'queue_create_conversions#run_job'
    match 'queue_conversion_notifications(/index)' => 'queue_conversion_notifications#index'
    match 'queue_conversion_notifications/run_job' => 'queue_conversion_notifications#run_job'
    match 'queue_create_device_identifiers(/index)' => 'queue_create_device_identifiers#index'
    match 'queue_create_invoices(/index)' => 'queue_create_invoices#index'
    match 'queue_daily_app_stats(/index)' => 'queue_daily_app_stats#index'
    match 'queue_downloads(/index)' => 'queue_downloads#index'
    match 'queue_failed_downloads(/index)' => 'queue_failed_downloads#index'
    match 'queue_failed_sdb_saves(/index)' => 'queue_failed_sdb_saves#index'
    match 'queue_get_store_info(/index)' => 'queue_get_store_info#index'
    match 'queue_hourly_app_stats(/index)' => 'queue_hourly_app_stats#index'
    match 'queue_mail_chimp_updates(/index)' => 'queue_mail_chimp_updates#index'
    match 'queue_mail_chimp_updates(/index)' => 'queue_mail_chimp_updates#index'
    match 'queue_partner_notifications(/index)' => 'queue_partner_notifications#index'
    match 'queue_recount_stats(/index)' => 'queue_recount_stats#index'
    match 'queue_resolve_support_requests(/index)' => 'queue_resolve_support_requests#index'
    match 'queue_sdb_backups(/index)' => 'queue_sdb_backups#index'
    match 'queue_select_vg_items(/index)' => 'queue_select_vg_items#index'
    match 'queue_send_currency(/index)' => 'queue_send_currency#index'
    match 'queue_send_currency/run_job' => 'queue_send_currency#run_job'
    match 'queue_send_failed_emails(/index)' => 'queue_send_failed_emails#index'
    match 'queue_send_welcome_emails(/index)' => 'queue_send_welcome_emails#index'
    match 'queue_send_welcome_emails_via_exact_target(/index)' => 'queue_send_welcome_emails_via_exact_target#index'
    match 'queue_suspicious_gamer_emails(/index)' => 'queue_suspicious_gamer_emails#index'
    match 'queue_terminate_nodes(/index)' => 'queue_terminate_nodes#index'
    match 'queue_third_party_tracking(/index)' => 'queue_third_party_tracking#index'
    match 'queue_udid_reports(/index)' => 'queue_udid_reports#index'
    match 'queue_update_monthly_account(/index)' => 'queue_update_monthly_account#index'
    match 'queue_update_papaya_devices(/index)' => 'queue_update_papaya_devices#index'
    match 'queue_update_papaya_user_count(/index)' => 'queue_update_papaya_user_count#index'
    match 'queue_record_updates(/index)' => 'queue_record_updates#index'
    match 'queue_record_updates/run_job' => 'queue_record_updates#run_job'
    match 'queue_cache_optimized_offer_list(/index)' => 'queue_cache_optimized_offer_list#index'
    match 'queue_cache_optimized_offer_list/run_job' => 'queue_cache_optimized_offer_list#run_job'
    match 'queue_cache_record_not_found(/index)' => 'queue_cache_record_not_found#index'
    match 'queue_cache_record_not_found/run_job' => 'queue_cache_record_not_found#run_job'
    match 'queue_send_coupon_emails(/index)' => 'queue_send_coupon_emails#index'
    match 'queue_send_coupon_emails/run_job' => 'queue_send_coupon_emails#run_job'
    match 'sqs_reader(/index)' => 'sqs_reader#index'
  end

  match 'statusz/index' => 'statusz#index'
  match 'statusz/queue_check' => 'statusz#queue_check'
  match 'statusz/slave_db_check' => 'statusz#slave_db_check'
  match 'statusz/memcached_check' => 'statusz#memcached_check'
  match 'statusz/master_healthz' => 'statusz#master_healthz'
end
