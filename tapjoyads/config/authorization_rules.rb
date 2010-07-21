authorization do
  
  role :payops do
    has_permission_on :tools, :to => [ :new_order, :create_order, :payouts, :create_payout, :money, :new_transfer, :create_transfer ]
  end
  
  role :account_mgr do
  end
  
  role :partner do
  end
  
  role :agency do
  end
  
  role :executive do
    has_permission_on :tools, :to => [ :money ]
    has_permission_on :statz, :to => [ :index, :show, :search ]
  end
  
  role :statz do
    has_permission_on :statz, :to => [ :index, :show, :edit, :update, :search, :last_run_times, :udids, :udid ]
    has_permission_on :tools, :to => [ :money ]
  end
  
  role :admin do
    includes :payops
    includes :statz
  end
  
end
