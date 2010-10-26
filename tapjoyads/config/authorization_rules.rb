authorization do

  role :partner do
    has_permission_on :apps, :to => [ :index, :show, :new, :create, :edit, :update, :confirm, :integrate, :publisher_integrate, :search, :sdk_download, :archive ]
    has_permission_on :offers, :to => [ :show, :update, :download_udids ]
    has_permission_on :currencies, :to => [ :show, :update, :new, :create, :reset_test_device ]
    has_permission_on :virtual_goods, :to => [ :show, :update, :new, :create, :index, :reorder ]
    has_permission_on :reporting, :to => [ :index, :show, :export ]
    has_permission_on :billing, :to => [ :index, :add_funds, :create_order, :export_statements, :export_orders, :export_payouts ]
    has_permission_on :users, :to => [ :index, :new, :create, :edit, :update ]
    has_permission_on :support, :to => [ :index ]
  end

  role :agency do
    has_permission_on :partners, :to => [ :index, :show, :make_current, :new, :create ]
  end
  
  role :tools do
    has_permission_on :tools, :to => [ :index ]
    has_permission_on :apps, :to => [ :unarchive ]
  end
  
  role :payops do
    includes :tools
    has_permission_on :tools, :to => [ :new_order, :create_order, :payouts, :create_payout, :money, :new_transfer, :create_transfer ]
  end
  
  role :executive do
    includes :tools
    has_permission_on :tools, :to => [ :money ]
    has_permission_on :statz, :to => [ :index, :show ]
    has_permission_on :search, :to => [ :offers  ]
  end
  
  role :statz do
    has_permission_on :statz, :to => [ :index, :show, :edit, :update, :new, :create, :last_run_times, :udids ]
    has_permission_on :search, :to => [ :offers ]
    has_permission_on :tools, :to => [ :disabled_popular_offers ]
    has_permission_on :activities, :to => [ :index ]
    has_permission_on :partners, :to => [ :index, :show, :make_current, :manage, :stop_managing ]
  end
  
  role :account_mgr do
    includes :payops
    includes :statz
    has_permission_on :rank_boosts, :to => [ :index, :new, :create, :edit, :update, :destroy ]
    has_permission_on :partners, :to => [ :update, :managed_by ]
  end
  
  role :raffle_manager do
    has_permission_on :raffle_manager, :to => [ :index, :new, :create, :edit, :update ]
  end
  
  role :admin do
    includes :tools
    includes :payops
    includes :executive
    includes :statz
    includes :raffle_manager
    includes :account_mgr
    
    has_permission_on :tools, :to => [ :failed_sdb_saves, :sdb_metadata, :reset_device ]
  end
end
