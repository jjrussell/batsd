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
  map.root :controller => :homepage, :action => 'start'
  map.connect 'site/:action', :controller => 'homepage'
  map.connect 'index.html', :controller => 'homepage', :action => 'index'

  map.register 'register', :controller => :sign_up, :action => :new
  map.login 'login', :controller => :user_sessions, :action => :new
  map.logout 'logout', :controller => :user_sessions, :action => :destroy
  map.resources :user_sessions, :only => [ :new, :create, :destroy ]
  map.resources :users, :as => :account, :except => [ :show, :destroy ]
  map.resources :apps, :except => [ :destroy ], :member => { :confirm => :get, :integrate => :get, :publisher_integrate => :get, :archive => :post, :unarchive => :post } do |app|
    app.resources :offers, :only => [ :show, :update ] , :member => { :download_udids => :get, :percentile => :post, :toggle => :post }, :controller => 'apps/offers'
    app.resources :currencies, :only => [ :show, :update, :new, :create ],
      :member => { :reset_test_device => :post }, :controller => 'apps/currencies'
    app.resources :virtual_goods, :as => 'virtual-goods', :only => [ :show, :update, :new, :create, :index ],
      :collection => { :reorder => :post }, :controller => 'apps/virtual_goods'
    app.resources :featured_offers, :only => [ :new, :create, :edit, :update ], :controller => 'apps/featured_offers'
  end
  map.resources :reporting, :only => [ :index, :show ], :member => { :export => :post }
  map.resources :billing, :only => [ :index, ], :collection => { :create_order => :post }
  map.add_funds_billing 'billing/add-funds', :controller => :billing, :action => :add_funds
  map.resources :support, :only => [ :index ],
    :collection => { :contact => :post }
  map.resources :tools, :only => :index,
    :collection => { :monthly_data => :get, :new_transfer => :get,
                     :payouts => :get, :money => :get, :failed_sdb_saves => :get, :disabled_popular_offers => :get,
                     :sdb_metadata => :get, :reset_device => :get, :failed_downloads => :get, :sanitize_users => :get,
                     :unresolved_clicks => :post, :resolve_clicks => :post, :sqs_lengths => :get },
    :member => { :create_payout => :post, :create_transfer => :post }
  map.resources :statz, :only => [ :index, :show, :edit, :update, :new, :create ],
    :member => { :last_run_times => :get, :udids => :get }
  map.resources :raffle_manager, :only => [ :index, :edit, :update, :new, :create ]
  map.resources :activities, :only => [ :index ]
  map.resources :partners, :only => [ :index, :show, :new, :create, :update, :edit ],
    :member => { :make_current => :post, :manage => :post, :stop_managing => :post, :mail_chimp_info => :get, :new_transfer => :get, :create_transfer => :post },
    :collection => { :managed_by => :get } do |partner|
      partner.resources :offer_discounts, :only => [ :index, :new, :create ], :member => { :deactivate => :post }, :controller => 'partners/offer_discounts'
  end
  map.resources :password_resets, :as => 'password-reset', :only => [ :new, :create, :edit, :update ]
  map.resources :rank_boosts, :except => [ :show, :destroy ], :member => { :deactivate => :post }
  map.with_options(:controller => 'search') do |m|
    m.search_offers 'search/offers', :action => 'offers'
  end
  map.premier 'premier', :controller => :premier, :action => :edit
  map.resources :preview_experiments, :only => [ :index, :show ]
  map.namespace :tools do |tools|
    tools.resources :premier_partners, :only => [ :index ]
    tools.resources :generic_offers, :only => [ :new, :create ]
    tools.resources :orders, :only => [ :new, :create ]
  end

  # Special paths:
  map.connect 'log_device_app/:action/:id', :controller => 'connect'
  map.connect 'confirm_email_validation', :controller => 'list_signup', :action => 'confirm_api'
  map.connect 'privacy', :controller => 'homepage', :action => 'privacy'
  map.connect 'privacy.html', :controller => 'homepage', :action => 'privacy'
  map.resources :opt_outs, :only => :create
  
  # Route old login page to new login page.
  map.connect 'Connect/Publish/Default.aspx', :controller => :user_sessions, :action => :new
  
  # Service1.asmx redirects. (Must include both lower-case and capital: service1.asmx and Service1.asmx).
  # These paths will be supported indefinitely - or as long as we support the legacy api.
  map.connect 'service1.asmx/Connect', :controller => 'connect'
  map.connect 'Service1.asmx/Connect', :controller => 'connect'
  map.connect 'service1.asmx/AdShown', :controller => 'adshown'
  map.connect 'Service1.asmx/AdShown', :controller => 'adshown'
  map.connect 'service1.asmx/SubmitTapjoyAdClick', :controller => 'submit_click', :action => 'ad'
  map.connect 'Service1.asmx/SubmitTapjoyAdClick', :controller => 'submit_click', :action => 'ad'
  map.connect 'service1.asmx/SubmitAppStoreClick', :controller => 'submit_click', :action => 'store'
  map.connect 'Service1.asmx/SubmitAppStoreClick', :controller => 'submit_click', :action => 'store'
  map.connect 'service1.asmx/GetAppIcon', :controller => 'get_app_image', :action => 'icon'
  map.connect 'Service1.asmx/GetAppIcon', :controller => 'get_app_image', :action => 'icon'
  map.connect 'service1.asmx/GetOffersForPublisherCurrencyByType', :controller => 'get_offers'
  map.connect 'Service1.asmx/GetOffersForPublisherCurrencyByType', :controller => 'get_offers'
  map.connect 'service1.asmx/GetTapjoyAd', :controller => 'getad'
  map.connect 'Service1.asmx/GetTapjoyAd', :controller => 'getad'
  map.connect 'service1.asmx/GetAdOrder', :controller => 'get_ad_order'
  map.connect 'Service1.asmx/GetAdOrder', :controller => 'get_ad_order'
  map.connect 'service1.asmx/SubmitOfferClick', :controller => 'submit_click', :action => 'offer'
  map.connect 'Service1.asmx/SubmitOfferClick', :controller => 'submit_click', :action => 'offer'
  map.connect 'service1.asmx/GetUserOfferStatus', :controller => 'offer_status'
  map.connect 'Service1.asmx/GetUserOfferStatus', :controller => 'offer_status'
  map.connect 'service1.asmx/GetAllVGStoreItems', :controller => 'get_vg_store_items', :action => 'all'
  map.connect 'Service1.asmx/GetAllVGStoreItems', :controller => 'get_vg_store_items', :action => 'all'
  map.connect 'service1.asmx/GetPurchasedVGStoreItems', :controller => 'get_vg_store_items', :action => 'purchased'
  map.connect 'Service1.asmx/GetPurchasedVGStoreItems', :controller => 'get_vg_store_items', :action => 'purchased'
  map.connect 'service1.asmx/GetUserAccountObject', :controller => 'get_vg_store_items', :action => 'user_account'
  map.connect 'Service1.asmx/GetUserAccountObject', :controller => 'get_vg_store_items', :action => 'user_account'
  map.connect 'service1.asmx/PurchaseVGWithCurrency', :controller => 'purchase_vg'
  map.connect 'Service1.asmx/PurchaseVGWithCurrency', :controller => 'purchase_vg'
  
  map.connect 'service1.asmx/:action', :controller => 'service1'
  map.connect 'Service1.asmx/:action', :controller => 'service1'
  
  # Generic windows redirectors. These will be transitions over to ruby controllers as
  # functionality is moved off of windows.
  map.connect 'TapDefenseCurrencyService.asmx/:action', :controller => 'win_redirector'
  map.connect 'TapPointsCurrencyService.asmx/:action', :controller => 'win_redirector'
  map.connect 'RingtoneService.asmx/:action', :controller => 'win_redirector'
  map.connect 'AppRedir.aspx/:action', :controller => 'win_redirector'
  map.connect 'Redir.aspx/:action', :controller => 'win_redirector'
  map.connect 'RateApp.aspx/:action', :controller => 'win_redirector'
  
  map.connect 'Offers.aspx/:action', :controller => 'win_redirector'
  
  # Authenticated windows redirectors. These too will be removed/moved to standard 
  # ruby controllers in time.
  map.connect 'CronService.asmx/:action', :controller => 'authenticated_win_redirector'
  
  map.resources :raffles, :only => [ :index, :edit, :update ], :collection => { :status => :get }, :member => { :purchase => :post }
  map.resources :surveys, :only => [ :edit, :create ]
  
  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller.:format'
  
end
