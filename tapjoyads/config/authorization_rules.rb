authorization do

  role :partner do
    has_permission_on :dashboard_apps, :to => [ :index, :show, :new, :create, :edit, :update, :confirm, :integrate, :publisher_integrate, :integrate_check, :search, :sdk_download, :archive ]
    has_permission_on :dashboard_offers, :to => [ :new, :create, :edit, :update, :toggle, :percentile, :preview ]
    has_permission_on :dashboard_offer_creatives, :to => [ :show, :create, :new, :destroy ]
    has_permission_on :dashboard_currencies, :to => [ :show, :update, :new, :create, :reset_test_device ]
    has_permission_on :dashboard_virtual_goods, :to => [ :show, :update, :new, :create, :index, :reorder ]
    has_permission_on :dashboard_enable_offer_requests, :to => [ :create ]
    has_permission_on :dashboard_reporting, :to => [ :index, :show, :export, :download_udids, :api, :regenerate_api_key, :aggregate, :export_aggregate ]
    has_permission_on :dashboard_action_offers, :to => [ :index, :new, :create, :edit, :update, :toggle, :TJCPPA, :TapjoyPPA, :preview ]
    has_permission_on :dashboard_reengagement_offers, :to => [ :index, :new, :create, :edit, :update, :destroy, :update_status ]
    has_permission_on :dashboard_billing, :to => [ :index, :add_funds, :transfer_funds, :payout_info, :update_payout_info, :create_transfer, :create_order, :export_statements, :export_orders, :export_payouts, :export_adjustments, :forget_credit_card ]
    has_permission_on :dashboard_users, :to => [ :index, :new, :create, :edit, :update ]
    has_permission_on :dashboard_support, :to => [ :index ]
    has_permission_on :dashboard_premier, :to => [ :edit, :update ]
    has_permission_on :dashboard_inventory_management, :to => [ :index, :per_app, :partner_promoted_offers, :promoted_offers ]
    has_permission_on :dashboard_offers_offer_events, :to => [ :index, :new, :create, :edit, :update, :destroy ]
    has_permission_on :dashboard_account_whitelist, :to => [ :index, :enable, :disable ]
  end

  role :agency do
    has_permission_on :dashboard_partners, :to => [ :index, :show, :make_current, :new, :create, :agency_api ]
  end

  role :tools do
    has_permission_on :dashboard_tools, :to => [ :index ]
  end

  role :file_sharer do
    includes :tools
    has_permission_on :dashboard_tools_shared_files, :to => [ :index, :create, :delete ]
  end

  role :ops do
    has_permission_on :dashboard_ops, :to => [
      :index,
      :elb_status,
      :as_groups,
      :as_header,
      :as_instances,
      :elb_deregister_instance,
      :ec2_reboot_instance,
      :as_terminate_instance,
      :service_stats,
      :http_codes,
      :bytes_sent
    ]
  end

  role :devices do
    includes :tools
    has_permission_on :dashboard_internal_devices, :to => [ :new, :edit, :update, :index, :show, :destroy, :approve ]
  end

  role :customer_service do
    includes :tools
    includes :devices
    includes :file_sharer
    has_permission_on :dashboard_search, :to => [ :gamers ]
    has_permission_on :dashboard_tools, :to => [ :resolve_clicks, :device_info, :update_device, :send_currency_failures ]
    has_permission_on :dashboard_tools_gamers, :to => [ :index, :show ]
    has_permission_on :dashboard_tools_gamer_devices, :to => [ :create, :edit, :new, :update ]
    has_permission_on :dashboard_tools_support_requests, :to => [ :index, :mass_resolve ]
  end

  role :customer_service_manager do
    includes :customer_service
    has_permission_on :dashboard_tools, :to => [ :award_currencies, :update_award_currencies ]
  end

  role :money do
    includes :tools
    includes :devices
    has_permission_on :dashboard_tools, :to => [ :money, :monthly_data ]
    has_permission_on :dashboard_tools_orders, :to => [ :new, :create ]
    has_permission_on :dashboard_tools_earnings_adjustments, :to => [ :new, :create ]
  end

  role :payops do
    includes :money
    has_permission_on :dashboard_tools_payouts, :to => [ :index, :export ]
    has_permission_on :dashboard_tools_orders, :to => [ :failed_invoices, :retry_invoicing, :mark_invoiced ]
    has_permission_on :dashboard_tools_network_costs, :to => [ :index, :new, :create ]
    has_permission_on :dashboard_tools_payout_freezes, :to => [ :index ]
  end

  role :payout_manager do
    includes :payops
    has_permission_on :dashboard_tools, :to => [ :payout_info, :publishers_without_payout_info, :publisher_payout_info_changes ]
    has_permission_on :dashboard_tools_payouts, :to => [ :create, :confirm_payouts ]
    has_permission_on :dashboard_tools_payout_freezes, :to => [ :create, :disable ]
  end

  role :reporting do
    has_permission_on :statz, :to => [ :index, :show, :global, :publisher, :advertiser, :support_request_reward_ratio ]
    has_permission_on :search, :to => [ :offers, :brands ]
  end

  role :executive do
    includes :tools
    includes :devices
    includes :reporting
    has_permission_on :dashboard_tools, :to => [ :money, :monthly_data ]
  end

  role :hr do
    includes :tools
    includes :devices
    has_permission_on :dashboard_tools_employees, :to => [ :index, :new, :create, :edit, :update, :delete_photo ]
  end

  role :account_mgr do
    includes :money
    includes :games_editor
    includes :customer_service
    includes :file_sharer
    has_permission_on :dashboard_users, :to => [ :approve ]
    has_permission_on :dashboard_statz, :to => [ :index, :show, :edit, :update, :new, :create, :last_run_times, :udids, :download_udids, :global, :publisher, :advertiser, :support_request_reward_ratio ]
    has_permission_on :dashboard_search, :to => [ :offers, :partners, :users, :currencies ]
    has_permission_on :dashboard_tools, :to => [ :disabled_popular_offers, :sanitize_users, :update_user, :resolve_clicks, :new_transfer, :device_info, :update_device, :send_currency_failures ]
    has_permission_on :dashboard_tools_enable_offer_requests, :to => [ :index, :update ]
    has_permission_on :dashboard_activities, :to => [ :index ]
    has_permission_on :dashboard_partners, :to => [ :index, :show, :edit, :make_current, :manage, :stop_managing, :mail_chimp_info, :update, :managed_by, :new_transfer, :create_transfer, :reporting, :agency_api, :set_tapjoy_sponsored, :set_unconfirmed_for_payout ]
    has_permission_on :dashboard_tools_rank_boosts, :to => [ :index, :new, :create, :edit, :update, :deactivate ]
    has_permission_on :dashboard_apps, :to => [ :unarchive ]
    has_permission_on :dashboard_offer_creatives, :to => [ :show, :create, :update, :destroy ]
    has_permission_on :dashboard_partners_offer_discounts, :to => [ :index, :new, :create, :deactivate ]
    has_permission_on :dashboard_tools_approvals, :to => [ :index, :history, :mine, :assign, :approve, :reject ]
    has_permission_on :dashboard_tools_offer_lists, :to => [ :index ]
    has_permission_on :dashboard_tools_premier_partners, :to => [ :index ]
    has_permission_on :dashboard_tools_generic_offers, :to => [ :index, :new, :create, :edit, :update ]
    has_permission_on :dashboard_tools_video_offers, :to => [ :new, :create, :edit, :update ]
    has_permission_on :dashboard_tools_video_offers_video_buttons, :to => [ :index, :new, :create, :edit, :update, :show ]
    has_permission_on :dashboard_tools_admin_devices, :to => [ :index, :new, :create, :edit, :update, :destroy ]
    has_permission_on :dashboard_tools_offer_events, :to => [ :index, :new, :create, :edit, :update, :destroy ]
    has_permission_on :dashboard_tools_external_publishers, :to => [ :index, :update ]
    has_permission_on :dashboard_tools_users, :to => [ :index, :show ]
    has_permission_on :dashboard_tools_users_partner_assignments, :to => [ :create, :destroy ]
    has_permission_on :dashboard_tools_agency_users, :to => [ :index, :show ]
    has_permission_on :dashboard_tools_partner_program_statz, :to => [ :index, :export ]
    has_permission_on :dashboard_tools_offers, :to => [ :creative, :approve_creative, :reject_creative ]
    has_permission_on :dashboard_tools_currency_approvals, :to => [ :index, :history, :approve, :reject]
    has_permission_on :dashboard_tools_survey_offers, :to => [ :index, :show, :new, :create, :edit, :update, :destroy, :toggle_enabled ]
    has_permission_on :dashboard_tools_brand_offers, :to => [ :index, :create, :delete ]
    has_permission_on :dashboard_tools_brands, :to => [ :index, :new, :create, :edit, :update, :show ]
    has_permission_on :dashboard_tools_clients, :to => [ :index, :show, :new, :create, :edit, :update, :add_partner, :remove_partner ]
  end

  role :games_editor do
    includes :tools
    has_permission_on :dashboard_tools_editors_picks, :to => [ :index, :new, :create, :show, :edit, :update, :activate, :expire ]
    has_permission_on :dashboard_tools_app_reviews, :to => [ :index, :new, :create, :edit, :update, :destroy ]
    has_permission_on :dashboard_tools_featured_contents, :to => [ :index, :new, :create, :edit, :update, :destroy ]
  end

  role :role_mgr do
    includes :tools
    has_permission_on :dashboard_tools, :to => [ :manage_user_roles, :update_user_roles ]
    has_permission_on :dashboard_tools_users, :to => [ :index, :show ]
    has_permission_on :dashboard_tools_users_role_assignments, :to => [ :create, :destroy ]
  end

  role :products do
    includes :tools
    has_permission_on :dashboard_tools_wfhs, :to => [ :index, :new, :create, :edit, :update, :destroy ]
    has_permission_on :dashboard_tools_employees, :to => [ :wfhs ]
  end

  role :partner_changer do
    includes :tools
    has_permission_on :tools_partner_changes, :to => [ :index, :new, :create, :destroy, :complete ]
  end

  role :admin do
    includes :tools
    includes :devices
    includes :payops
    includes :ops
    includes :executive
    includes :account_mgr
    includes :hr
    includes :games_editor
    includes :role_mgr
    includes :products
    includes :file_sharer
    has_permission_on :dashboard_pub_offer_whitelist, :to => [ :index, :enable, :disable ]
    has_permission_on :dashboard_tools, :to => [ :failed_sdb_saves, :sdb_metadata, :reset_device, :sqs_lengths, :elb_status, :ses_status, :as_groups, :fix_rewards ]
    has_permission_on :dashboard_tools_offers, :to => [ :creative, :approve_creative, :reject_creative ]
    has_permission_on :dashboard_tools_recommenders, :to => [ :index, :create ]
    has_permission_on :dashboard_tools_jobs, :to => [ :index, :new, :create, :edit, :update, :destroy ]
    has_permission_on :dashboard_tools_support_requests, :to => [ :index, :mass_resolve ]
    has_permission_on :dashboard_tools_press_releases, :to => [ :index, :new, :create, :edit, :update ]
  end
end
