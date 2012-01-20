authorization do

  role :partner do
    has_permission_on :apps, :to => [ :index, :show, :new, :create, :edit, :update, :confirm, :integrate, :publisher_integrate, :search, :sdk_download, :archive ]
    has_permission_on :apps_offers, :to => [ :new, :create, :edit, :update, :toggle, :percentile, :preview, :upload_creative ]
    has_permission_on :apps_currencies, :to => [ :show, :update, :new, :create, :reset_test_device ]
    has_permission_on :apps_virtual_goods, :to => [ :show, :update, :new, :create, :index, :reorder ]
    has_permission_on :enable_offer_requests, :to => [ :create ]
    has_permission_on :reporting, :to => [ :index, :show, :export, :download_udids, :api, :regenerate_api_key, :aggregate, :export_aggregate ]
    has_permission_on :apps_action_offers, :to => [ :index, :new, :create, :edit, :update, :toggle, :TJCPPA, :TapjoyPPA, :preview ]
    has_permission_on :billing, :to => [ :index, :add_funds, :transfer_funds, :payout_info, :update_payout_info, :create_transfer, :create_order, :export_statements, :export_orders, :export_payouts, :export_adjustments, :forget_credit_card ]
    has_permission_on :users, :to => [ :index, :new, :create, :edit, :update ]
    has_permission_on :support, :to => [ :index ]
    has_permission_on :premier, :to => [ :edit, :update ]
    has_permission_on :apps_offers_offer_events, :to => [ :index, :new, :create, :edit, :update, :destroy ]
    has_permission_on :account_whitelist, :to => [ :index, :enable, :disable ]
  end

  role :agency do
    has_permission_on :partners, :to => [ :index, :show, :make_current, :new, :create, :agency_api ]
  end

  role :tools do
    has_permission_on :tools, :to => [ :index ]
    has_permission_on :internal_devices, :to => [ :new, :edit, :update, :index, :show, :destroy, :approve ]
  end

  role :customer_service do
    includes :tools
    has_permission_on :tools, :to => [ :resolve_clicks, :device_info, :update_device, :award_currencies, :update_award_currencies, :send_currency_failures ]
    has_permission_on :tools_support_requests, :to => [ :index, :mass_resolve ]
  end

  role :money do
    includes :tools
    has_permission_on :tools, :to => [ :money, :monthly_data ]
    has_permission_on :tools_orders, :to => [ :new, :create ]
    has_permission_on :tools_earnings_adjustments, :to => [ :new, :create ]
  end

  role :payops do
    includes :money
    has_permission_on :tools_payouts, :to => [ :index ]
    has_permission_on :tools_orders, :to => [ :failed_invoices, :retry_invoicing, :mark_invoiced ]
    has_permission_on :tools_network_costs, :to => [ :index, :new, :create ]
    has_permission_on :tools_payout_freezes, :to => [ :index ]
  end

  role :payout_manager do
    includes :payops
    has_permission_on :tools, :to => [ :payout_info, :publishers_without_payout_info, :publisher_payout_info_changes ]
    has_permission_on :tools_payouts, :to => [ :create ]
    has_permission_on :tools_payout_freezes, :to => [ :create, :disable ]
  end

  role :reporting do
    has_permission_on :statz, :to => [ :index, :show, :global, :publisher, :advertiser, :support_request_reward_ratio ]
    has_permission_on :search, :to => [ :offers ]
  end

  role :executive do
    includes :tools
    includes :reporting
    has_permission_on :tools, :to => [ :money, :monthly_data ]
  end

  role :hr do
    includes :tools
    has_permission_on :tools_employees, :to => [ :index, :new, :create, :edit, :update, :delete_photo ]
  end

  role :account_mgr do
    includes :money
    includes :games_editor
    has_permission_on :statz, :to => [ :index, :show, :edit, :update, :new, :create, :last_run_times, :udids, :download_udids, :global, :publisher, :advertiser, :support_request_reward_ratio ]
    has_permission_on :search, :to => [ :offers, :partners, :users ]
    has_permission_on :tools, :to => [ :disabled_popular_offers, :sanitize_users, :update_user, :resolve_clicks, :new_transfer, :edit_android_app, :update_android_app, :device_info, :update_device, :freemium_android, :award_currencies, :update_award_currencies, :send_currency_failures ]
    has_permission_on :tools_enable_offer_requests, :to => [ :index, :update ]
    has_permission_on :activities, :to => [ :index ]
    has_permission_on :partners, :to => [ :index, :show, :edit, :make_current, :manage, :stop_managing, :mail_chimp_info, :update, :managed_by, :new_marketing_credits, :create_marketing_credits, :new_transfer, :create_transfer, :reporting, :agency_api, :set_tapjoy_sponsored ]
    has_permission_on :tools_rank_boosts, :to => [ :index, :new, :create, :edit, :update, :deactivate ]
    has_permission_on :apps, :to => [ :unarchive ]
    has_permission_on :partners_offer_discounts, :to => [ :index, :new, :create, :deactivate ]
    has_permission_on :tools_offer_lists, :to => [ :index ]
    has_permission_on :tools_premier_partners, :to => [ :index ]
    has_permission_on :tools_generic_offers, :to => [ :index, :new, :create, :edit, :update ]
    has_permission_on :tools_video_offers, :to => [ :new, :create, :edit, :update ]
    has_permission_on :tools_video_offers_video_buttons, :to => [ :index, :new, :create, :edit, :update, :show ]
    has_permission_on :tools_admin_devices, :to => [ :index, :new, :create, :edit, :update, :destroy ]
    has_permission_on :tools_offer_events, :to => [ :index, :new, :create, :edit, :update, :destroy ]
    has_permission_on :tools_external_publishers, :to => [ :index, :update ]
    has_permission_on :tools_users, :to => [ :index, :show ]
    has_permission_on :tools_users_partner_assignments, :to => [ :create, :destroy ]
    has_permission_on :tools_agency_users, :to => [ :index, :show ]
    has_permission_on :tools_partner_program_statz, :to => [ :index, :export ]
    has_permission_on :tools_offers, :to => [ :creative, :approve_creative, :reject_creative ]
  end

  role :games_editor do
    has_permission_on :tools, :to => [ :index ]
    has_permission_on :tools_editors_picks, :to => [ :index, :new, :create, :show, :edit, :update, :activate, :expire ]
    has_permission_on :tools_app_reviews, :to => [ :index, :new, :create, :edit, :update, :update_featured, :destroy ]
    has_permission_on :tools_featured_contents, :to => [ :index, :new, :create, :edit, :update, :destroy ]
  end

  role :admin do
    includes :tools
    includes :payops
    includes :executive
    includes :account_mgr
    includes :hr
    includes :games_editor
    has_permission_on :pub_offer_whitelist, :to => [ :index, :enable, :disable ]
    has_permission_on :tools, :to => [ :failed_sdb_saves, :sdb_metadata, :reset_device, :sqs_lengths, :elb_status, :ses_status, :as_groups, :manage_user_roles, :update_user_roles ]
    has_permission_on :tools_offers, :to => [ :creative, :approve_creative, :reject_creative ]
    has_permission_on :tools_users_role_assignments, :to => [ :create, :destroy ]
    has_permission_on :tools_jobs, :to => [ :index, :new, :create, :edit, :update, :destroy ]
    has_permission_on :tools_support_requests, :to => [ :index, :mass_resolve ]
    has_permission_on :tools_press_releases, :to => [ :index, :new, :create, :edit, :update ]
  end
end
