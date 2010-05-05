authorization do
  
  role :payops do
    has_permission_on :tools, :to => [ :payouts, :create_payout ]
  end
  
  role :account_mgr do
  end
  
  role :partner do
  end
  
  role :agency do
  end
  
  role :executive do
  end
  
  role :admin do
    includes :payops
    has_permission_on :statz, :to => :index
  end
  
end
