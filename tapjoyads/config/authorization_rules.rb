authorization do

  role :partner do
    has_permission_on :apps, :to => [ :index, :show, :new, :create, :edit, :update, :confirm, :integrate, :publisher_integrate, :search, :sdk_download, :archive ]
    has_permission_on :apps_offers, :to => [ :show, :update, :percentile, :toggle ]
    has_permission_on :apps_featured_offers, :to => [ :new, :create, :edit, :update ]
    has_permission_on :apps_currencies, :to => [ :show, :update, :new, :create, :reset_test_device ]
    has_permission_on :apps_virtual_goods, :to => [ :show, :update, :new, :create, :index, :reorder ]
    has_permission_on :reporting, :to => [ :index, :show, :export, :download_udids ]
    has_permission_on :apps_action_offers, :to => [ :index, :new, :create, :edit, :update, :toggle, :TJCPPA, :TapjoyPPA ]
    has_permission_on :billing, :to => [ :index, :add_funds, :transfer_funds, :create_transfer, :create_order, :export_statements, :export_orders, :export_payouts ]
    has_permission_on :analytics, :to => [ :index, :create_apsalar_account ]
    has_permission_on :users, :to => [ :index, :new, :create, :edit, :update ]
    has_permission_on :support, :to => [ :index ]
    has_permission_on :premier, :to => [ :edit, :update ]
  end

  role :agency do
    has_permission_on :partners, :to => [ :index, :show, :make_current, :new, :create ]
  end
  
  role :tools do
    has_permission_on :tools, :to => [ :index ]
  end
  
  role :customer_service do
    includes :tools
    has_permission_on :tools, :to => [ :unresolved_clicks, :resolve_clicks ]
  end
  
  role :payops do
    includes :tools
    has_permission_on :tools, :to => [ :money, :monthly_data ]
    has_permission_on :tools_orders, :to => [ :new, :create ]
    has_permission_on :tools_payouts, :to => [ :index, :create ]
  end
  
  role :executive do
    includes :tools
    has_permission_on :tools, :to => [ :money, :monthly_data ]
    has_permission_on :statz, :to => [ :index, :show ]
    has_permission_on :search, :to => [ :offers ]
  end
  
  role :account_mgr do
    includes :payops
    has_permission_on :statz, :to => [ :index, :show, :edit, :update, :new, :create, :last_run_times, :udids ]
    has_permission_on :search, :to => [ :offers ]
    has_permission_on :tools, :to => [ :disabled_popular_offers, :sanitize_users, :update_user, :unresolved_clicks, :resolve_clicks, :new_transfer, :edit_android_app, :update_android_app, :device_info, :update_device ]
    has_permission_on :activities, :to => [ :index ]
    has_permission_on :partners, :to => [ :index, :show, :edit, :make_current, :manage, :stop_managing, :mail_chimp_info, :update, :managed_by, :new_transfer, :create_transfer ]
    has_permission_on :rank_boosts, :to => [ :index, :new, :create, :edit, :update, :deactivate ]
    has_permission_on :apps, :to => [ :unarchive ]
    has_permission_on :partners_offer_discounts, :to => [ :index, :new, :create, :deactivate ]
    has_permission_on :preview_experiments, :to => [ :index, :show ]
    has_permission_on :tools_premier_partners, :to => [ :index ]
    has_permission_on :tools_generic_offers, :to => [ :new, :create ]
  end
  
  role :raffle_manager do
    has_permission_on :raffle_manager, :to => [ :index, :new, :create, :edit, :update ]
  end
  
  role :admin do
    includes :tools
    includes :payops
    includes :executive
    includes :raffle_manager
    includes :account_mgr

    has_permission_on :tools, :to => [ :failed_sdb_saves, :sdb_metadata, :reset_device, :failed_downloads, :sqs_lengths, :elb_status, :as_groups ]
  end
end
