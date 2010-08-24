authorization do
  
  role :beta_website do
    has_permission_on :home, :to => [ :index ]
    has_permission_on :apps, :to => [ :index, :show, :new, :create, :edit, :update, :confirm, :pay_per_install , :pay_per_action, :integrate ]
    has_permission_on :offers, :to => [ :show, :update ]
    has_permission_on :reporting, :to => [ :index, :show ]
    has_permission_on :billing, :to => [ :index, :add_funds, :export_statements, :export_orders, :export_payouts ]
    has_permission_on :account, :to => [ :index ]
    has_permission_on :support, :to => [ :index ]
  end
  
  role :partner do
  end
  
  role :agency do
  end
  
  role :tools do
    has_permission_on :tools, :to => [ :index ]
  end
  
  role :payops do
    includes :tools
    has_permission_on :tools, :to => [ :new_order, :create_order, :payouts, :create_payout, :money, :new_transfer, :create_transfer ]
  end
  
  role :executive do
    includes :tools
    has_permission_on :tools, :to => [ :money ]
    has_permission_on :statz, :to => [ :index, :show, :search ]
  end
  
  role :statz do
    has_permission_on :statz, :to => [ :index, :show, :edit, :update, :new, :create, :search, :last_run_times, :udids, :download_udids ]
    has_permission_on :tools, :to => [ :disabled_popular_offers ]
    has_permission_on :activities, :to => [ :index ]
    has_permission_on :partners, :to => [ :index, :show ]
  end
  
  role :account_mgr do
    includes :payops
    includes :statz
  end
  
  role :raffle_manager do
    has_permission_on :raffle_manager, :to => [ :index, :new, :create, :edit, :update ]
  end
  
  role :admin do
    includes :beta_website
    includes :tools
    includes :payops
    includes :executive
    includes :statz
    includes :raffle_manager
    
    has_permission_on :tools, :to => [ :failed_sdb_saves ]
  end
  
end
