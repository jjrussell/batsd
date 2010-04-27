authorization do
  
  role :tools_user do
    has_permission_on :tools, :to => [ :index ]
  end
  
  role :admin do
    includes :tools_user
  end
  
end
