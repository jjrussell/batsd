ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"
  
  # website-specific routes
  
  map.with_options({:path_prefix => MACHINE_TYPE == 'games' ? '' : 'games', :name_prefix => 'games_'}) do |m|
    m.root :controller => 'games/homepage', :action => :index
  end
  
  break if MACHINE_TYPE == 'games'
  
  map.root :controller => :homepage, :action => 'start'
  map.connect 'site/:action', :controller => 'homepage'
  map.connect 'index.html', :controller => 'homepage', :action => 'index'

  map.register 'register', :controller => :sign_up, :action => :new
  map.login 'login', :controller => :user_sessions, :action => :new
  
  map.logout 'logout', :controller => :user_sessions, :action => :destroy
  
  map.namespace :account do |account|
    account.resources :whitelist, :controller => 'whitelist', :only => [ :index ], :member => [ :enable, :disable ]
  end  
  map.resources :user_sessions, :only => [ :new, :create, :destroy ]
  map.resources :users, :as => :account, :except => [ :show, :destroy ]
  map.resources :apps, :except => [ :destroy ], :member => { :confirm => :get, :integrate => :get, :publisher_integrate => :get, :archive => :post, :unarchive => :post } do |app|
    app.resources :offers, :only => [ :show, :update ] , :member => { :percentile => :post, :toggle => :post }, :controller => 'apps/offers' do |offer|
      offer.resources :offer_events, :only => [ :index, :new, :create, :edit, :update, :destroy ], :controller => 'apps/offers/offer_events', :as => :scheduling
    end
    app.resources :currencies, :only => [ :show, :update, :new, :create ],
      :member => { :reset_test_device => :post }, :controller => 'apps/currencies'
    app.resources :virtual_goods, :as => 'virtual-goods', :only => [ :show, :update, :new, :create, :index ],
      :collection => { :reorder => :post }, :controller => 'apps/virtual_goods'
    app.resources :featured_offers, :only => [ :new, :create, :edit, :update ], :controller => 'apps/featured_offers'
    app.resources :action_offers, :only => [ :new, :create, :edit, :update, :index ], :member => { :toggle => :post }, :collection => { :TJCPPA => :get, :TapjoyPPA => :get }, :controller => 'apps/action_offers'
  end
  map.resources :enable_offer_requests, :only => [ :create ]
  map.resources :reporting, :only => [ :index, :show ], :member => { :export => :post, :download_udids => :get }, :collection => { :api => :get, :regenerate_api_key => :post }
  map.resources :analytics, :only => [ :index ]
  map.create_apsalar_account_analytics 'analytics/create-apsalar-account', :controller => :analytics, :action => :create_apsalar_account
  map.share_data_analytics 'analytics/share-data', :controller => :analytics, :action => :share_data
  map.agree_to_share_data_analytics 'analytics/agree-to-share-data', :controller => :analytics, :action => :agree_to_share_data
  map.resources :billing, :only => [ :index ],
    :collection => { :create_order => :post, :create_transfer => :post, :update_payout_info => :post, :forget_credit_card => :post }
  map.add_funds_billing 'billing/add-funds', :controller => :billing, :action => :add_funds
  map.transfer_funds_billing 'billing/transfer-funds', :controller => :billing, :action => :transfer_funds
  map.payout_info_billing 'billing/payment-info', :controller => :billing, :action => :payout_info
  map.resources :support, :only => [ :index ],
    :collection => { :contact => :post }
  map.resources :tools, :only => :index,
    :collection => { :monthly_data => :get, :new_transfer => :get,
                     :money => :get, :failed_sdb_saves => :get, :disabled_popular_offers => :get, :as_groups => :get,
                     :sdb_metadata => :get, :reset_device => :get, :send_currency_failures => :get, :sanitize_users => :get,
                     :resolve_clicks => :post, :sqs_lengths => :get, :elb_status => :get, :capped_publishers => :get,
                     :publishers_without_payout_info => :get, :publisher_payout_info_changes => :get, :device_info => :get,
                     :freemium_android => :get },
    :member => {  :edit_android_app => :get, :update_android_app => :post, :update_user_roles => :post }
  map.resources :statz, :only => [ :index, :show, :edit, :update, :new, :create ],
    :member => { :last_run_times => :get, :udids => :get, :download_udids => :get },
    :collection => { :global => :get, :publisher => :get, :advertiser => :get }
  map.resources :raffle_manager, :only => [ :index, :edit, :update, :new, :create ]
  map.resources :activities, :only => [ :index ]
  map.resources :partners, :only => [ :index, :show, :new, :create, :update, :edit ],
    :member => { :make_current => :post, :manage => :post, :stop_managing => :post, :mail_chimp_info => :get, :new_transfer => :get, :create_transfer => :post, :reporting => :get, :delink_user => :post },
    :collection => { :managed_by => :get } do |partner|
    partner.resources :offer_discounts, :only => [ :index, :new, :create ], :member => { :deactivate => :post }, :controller => 'partners/offer_discounts'
    partner.resources :payout_infos, :only => [ :index, :update ]
  end
  map.resources :password_resets, :as => 'password-reset', :only => [ :new, :create, :edit, :update ]
  map.resources :rank_boosts, :except => [ :show, :destroy ], :member => { :deactivate => :post }
  map.with_options(:controller => 'search') do |m|
    m.search_offers 'search/offers', :action => 'offers'
    m.search_users 'search/users', :action => 'users'
  end
  map.premier 'premier', :controller => :premier, :action => :edit
  map.resources :preview_experiments, :only => [ :index, :show ]
  map.namespace :tools do |tools|
    tools.resources :premier_partners, :only => [ :index ]
    tools.resources :generic_offers, :only => [ :new, :create ]
    tools.resources :orders, :only => [ :new, :create ]
    tools.resources :payouts, :only => [ :index, :create ]
    tools.resources :enable_offer_requests, :only => [ :update, :index ]
    tools.resources :admin_devices, :only => [ :index, :new, :create, :edit, :update, :destroy ]
    tools.resources :offer_events, :only => [ :index, :new, :create, :edit, :update, :destroy ], :as => :scheduling
    tools.resources :users, :only  => [ :index, :show] do |user|
      user.resources :role_assignments, :only => [ :create, :destroy ], :controller => 'users/role_assignments'
    end
    tools.resources :employees, :only => [ :index, :new, :create, :edit, :update ], :member => [ :delete_photo ]

  end
  
  map.resources :offer_instructions, :only => [ :index ]
  map.with_options :controller => :game_state do |m|
    m.load_game_state 'game_state/load', :action => :load
    m.save_game_state 'game_state/save', :action => :save
  end
  
  # Special paths:
  map.connect 'log_device_app/:action/:id', :controller => 'connect'
  map.connect 'confirm_email_validation', :controller => 'list_signup', :action => 'confirm_api'
  map.connect 'privacy', :controller => 'homepage', :action => 'privacy'
  map.connect 'privacy.html', :controller => 'homepage', :action => 'privacy'
  map.connect 'press', :controller => 'homepage/press', :action => 'index'
  map.connect 'press/:id', :controller => 'homepage/press', :action => 'show'
  map.connect 'glu', :controller => 'homepage/press', :action => 'glu'
  map.connect 'publishing', :controller => 'homepage', :action => 'publishers'
  map.resources :sdk, :only => [ :index, :show ]
  map.resources :opt_outs, :only => :create
  map.namespace :agency_api do |agency|
    agency.resources :apps, :only => [ :index, :show, :create, :update ]
    agency.resources :partners, :only => :create, :collection => { :link => :post }
    agency.resources :currencies, :only => [ :index, :show, :create, :update ]
  end
  
  map.resources :raffles, :only => [ :index, :edit, :update ], :collection => { :status => :get }, :member => { :purchase => :post }
  map.resources :surveys, :only => [ :edit, :create ]
  
  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller.:format'
  
end
