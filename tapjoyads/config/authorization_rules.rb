authorization do
  
  role :admin do
    has_permission_on :user_partners, :to => [ :index, :new, :create, :edit, :update ]
    has_permission_on :user_user_roles, :to => [ :index, :new, :create, :edit, :update, :destroy ]
  end
  
  role :offerpal do
  end
  
  role :guest do
  end
  
end
