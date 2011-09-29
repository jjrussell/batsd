ActionController::Routing::Routes.draw do |map|
  map.with_options({:path_prefix => MACHINE_TYPE == 'dashboard' ? '' : 'dashboard', :name_prefix => 'dashboard_'}) do |m|
    m.root :controller => 'dashboard/homepage', :action => :index
  end
  
  map.resource :sign_up, :controller => :sign_up, :only => :create
  map.register 'register', :controller => :sign_up, :action => :new
  map.login 'login', :controller => :user_sessions, :action => :new
  map.logout 'logout', :controller => :user_sessions, :action => :destroy
  map.resources :password_resets, :as => 'password-reset', :only => [ :new, :create, :edit, :update ]
  map.resources :internal_devices, :only => [ :index, :show, :destroy, :edit, :update ], :member => { :block => :get }
  map.new_internal_device 'approve_device', :controller => :internal_devices, :action => 'new', :conditions => { :method => :get }
  map.approve_internal_device 'approve_device/:id', :controller => :internal_devices, :action => 'approve', :conditions => { :method => :get }
  
  map.resources :sdk, :only => [ :index, :show ], :collection => { :popup => :get, :license => :get }
  
  map.namespace :agency_api do |agency|
    agency.resources :apps, :only => [ :index, :show, :create, :update ]
    agency.resources :partners, :only => [ :index, :show, :create, :update ], :collection => { :link => :post }
    agency.resources :currencies, :only => [ :index, :show, :create, :update ]
  end
  map.connect 'create_account', :controller => :create_account, :action => :index
  map.resources :reporting_data, :only => :index, :collection => { :udids => :get }
  
  map.namespace :account do |account|
    account.resources :whitelist, :controller => 'whitelist', :only => [ :index ], :collection => [ :enable, :disable ]
  end  
  map.resources :user_sessions, :only => [ :new, :create, :destroy ]
  map.resources :users, :as => :account, :except => [ :show, :destroy ]
  map.resources :apps, :except => [ :destroy ], :member => { :confirm => :get, :integrate => :get, :publisher_integrate => :get, :archive => :post, :unarchive => :post }, :collection => { :search => :get } do |app|
    app.resources :offers, :only => [ :new, :create, :edit, :update ] , :member => { :toggle => :post, :percentile => :post, :preview => :get }, :controller => 'apps/offers' do |offer|
      offer.resources :offer_events, :only => [ :index, :new, :create, :edit, :update, :destroy ], :controller => 'apps/offers/offer_events', :as => :scheduling
    end
    app.resources :currencies, :only => [ :show, :update, :new, :create ],
      :member => { :reset_test_device => :post }, :controller => 'apps/currencies'
    app.resources :virtual_goods, :as => 'virtual-goods', :only => [ :show, :update, :new, :create, :index ],
      :collection => { :reorder => :post }, :controller => 'apps/virtual_goods'
    app.resources :action_offers, :only => [ :new, :create, :edit, :update, :index ], :member => { :toggle => :post, :preview => :get }, :collection => { :TJCPPA => :get, :TapjoyPPA => :get }, :controller => 'apps/action_offers'
  end
  map.resources :enable_offer_requests, :only => [ :create ]
  map.resources :reporting, :only => [ :index, :show ], :member => { :export => :post, :download_udids => :get }, :collection => { :aggregate => :get, :export_aggregate => :post, :api => :get, :regenerate_api_key => :post }
  map.resources :billing, :only => [ :index ],
    :collection => { :create_order => :post, :create_transfer => :post, :update_payout_info => :post, :forget_credit_card => :post, :export_statements => :get, :export_orders => :get, :export_payouts => :get, :export_adjustments => :get }
  map.add_funds_billing 'billing/add-funds', :controller => :billing, :action => :add_funds
  map.transfer_funds_billing 'billing/transfer-funds', :controller => :billing, :action => :transfer_funds
  map.payout_info_billing 'billing/payment-info', :controller => :billing, :action => :payout_info
  map.resources :statz, :only => [ :index, :show, :edit, :update, :new, :create ],
    :member => { :last_run_times => :get, :udids => :get, :download_udids => :get },
    :collection => { :global => :get, :publisher => :get, :advertiser => :get, :gamez => :get }
  map.resources :activities, :only => [ :index ]
  map.resources :partners, :only => [ :index, :show, :new, :create, :update, :edit ],
    :member => { :make_current => :post, :manage => :post, :stop_managing => :post, :mail_chimp_info => :get, :new_transfer => :get, :create_transfer => :post, :reporting => :get },
    :collection => { :agency_api => :get } do |partner|
    partner.resources :offer_discounts, :only => [ :index, :new, :create ], :member => { :deactivate => :post }, :controller => 'partners/offer_discounts'
    partner.resources :payout_infos, :only => [ :index, :update ]
  end
  map.connect 'partners/managed_by/:id', :controller => :partners, :action => :managed_by
  map.with_options(:controller => 'search') do |m|
    m.search_offers 'search/offers', :action => 'offers'
    m.search_users 'search/users', :action => 'users'
    m.search_partners 'search/partners', :action => 'partners'
  end
  map.resource :premier, :controller => :premier, :only => [ :update ]
  map.premier 'premier', :controller => :premier, :action => :edit
  
  # Admin tools routes
  map.resources :tools, :only => :index,
    :collection => { :monthly_data => :get, :new_transfer => :get,
                     :money => :get, :failed_sdb_saves => :get, :disabled_popular_offers => :get, :as_groups => :get,
                     :sdb_metadata => :get, :reset_device => :get, :send_currency_failures => :get, :sanitize_users => :get,
                     :resolve_clicks => :post, :sqs_lengths => :get, :elb_status => :get, :ses_status => :get,
                     :publishers_without_payout_info => :get, :publisher_payout_info_changes => :get, :device_info => :get,
                     :freemium_android => :get, :award_currencies => :post, :update_award_currencies => :post,
                     :edit_android_app => :get, :update_android_app => :post, :update_user_roles => :post, :update_device => :post }
  map.namespace :tools do |tools|
    tools.resources :premier_partners, :only => [ :index ]
    tools.resources :generic_offers, :only => [ :new, :create, :edit, :update ]
    tools.resources :orders, :only => [ :new, :create ],
      :member => { :mark_invoiced => :put, :retry_invoicing => :put },
      :collection => { :failed_invoices => :get }
    tools.resources :video_offers, :only => [ :new, :create, :edit, :update ] do |video_offer|
      video_offer.resources :video_buttons, :controller => 'video_offers/video_buttons'
    end
    tools.resources :payouts, :only => [ :index, :create ], :member => { :info => :get }
    tools.resources :enable_offer_requests, :only => [ :update, :index ]
    tools.resources :admin_devices, :only => [ :index, :new, :create, :edit, :update, :destroy ]
    tools.resources :offer_events, :only => [ :index, :new, :create, :edit, :update, :destroy ], :as => :scheduling
    tools.resources :users, :only  => [ :index, :show] do |user|
      user.resources :role_assignments, :only => [ :create, :destroy ], :controller => 'users/role_assignments'
      user.resources :partner_assignments, :only => [ :create, :destroy ], :controller => 'users/partner_assignments'
    end
    tools.resources :employees, :only => [ :index, :new, :create, :edit, :update ], :member => [ :delete_photo ]
    tools.resources :offer_lists, :only => [ :index ]
    tools.resources :rank_boosts, :except => [ :show, :destroy ], :member => { :deactivate => :post }
    tools.resources :external_publishers, :only => [ :index, :update ]
    tools.resources :jobs, :except => [ :show ]
    tools.resources :earnings_adjustments, :only => [ :new, :create ]
    tools.resources :editors_picks, :except => [ :destroy ], :member => { :activate => :post, :expire => :post }
    tools.resources :app_reviews, :except => [ :show ], :member => { :update_featured => :put }
    tools.resources :agency_users, :only => [ :index, :show ]
    tools.resources :support_requests, :only => [ :index ]
    tools.resources :press_releases, :only => [ :index, :new, :create, :edit, :update ]
  end
  
  map.connect 'mail_chimp_callback/callback', :controller => :mail_chimp_callback, :action => :callback
  
  map.connect 'adways_data',          :controller => :adways_data,          :action => :index
  map.connect 'brooklyn_packet_data', :controller => :brooklyn_packet_data, :action => :index
  map.connect 'ea_data',              :controller => :ea_data,              :action => :index
  map.connect 'fluent_data',          :controller => :fluent_data,          :action => :index
  map.connect 'glu_data',             :controller => :glu_data,             :action => :index
  map.connect 'gogii_data',           :controller => :gogii_data,           :action => :index
  map.connect 'loopt_data',           :controller => :loopt_data,           :action => :index
  map.connect 'ngmoco_data',          :controller => :ngmoco_data,          :action => :index
  map.connect 'pinger_data',          :controller => :pinger_data,          :action => :index
  map.connect 'pocketgems_data',      :controller => :pocketgems_data,      :action => :index
  map.connect 'sgn_data',             :controller => :sgn_data,             :action => :index
  map.connect 'zynga_data',           :controller => :zynga_data,           :action => :index
  map.connect 'tapulous_marketing',   :controller => :tapulous_marketing,   :action => :index
end
