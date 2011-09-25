ActionController::Routing::Routes.draw do |map|
  map.connect 'healthz', :controller => :healthz, :action => :index
  
  map.with_options({:path_prefix => MACHINE_TYPE == 'games' ? '' : 'games', :name_prefix => 'games_'}) do |m|
    m.root :controller => 'games/homepage', :action => :index
    m.tos 'tos', :controller => 'games/homepage', :action => :tos
    m.privacy 'privacy', :controller => 'games/homepage', :action => :privacy
    
    m.more_games_editor_picks 'editor_picks', :controller => 'games/more_games', :action => :editor_picks
    m.more_games_popular 'popular', :controller => 'games/more_games', :action => :popular
    
    m.resources :gamer_sessions, :controller => 'games/gamer_sessions', :only => [ :new, :create, :destroy ]
    m.login 'login', :controller => 'games/gamer_sessions', :action => :new
    m.logout 'logout', :controller => 'games/gamer_sessions', :action => :destroy
    
    m.resource :gamer, :controller => 'games/gamers', :only => [ :create, :edit, :update ] do |gamer|
      gamer.resource :device, :controller => 'games/gamers/devices', :only => [ :new, :create ], :member => { :finalize => :get }
    end
    m.register 'register', :controller => 'games/gamers', :action => :new
    
    m.resources :confirmations, :controller => 'games/confirmations', :only => [ :create ]
    m.confirm 'confirm', :controller => 'games/confirmations', :action => :create
    
    m.resources :password_resets, :controller => 'games/password_resets', :as => 'password-reset', :only => [ :new, :create, :edit, :update ]
    
    m.resources :support_requests, :controller => 'games/support_requests', :only => [ :new, :create ]

  end

  break if MACHINE_TYPE == 'games'
  
  # Homepage routes
  map.root :controller => :homepage, :action => 'start'
  map.connect 'site/:action', :controller => 'homepage'
  map.connect 'index.html', :controller => 'homepage', :action => 'index'
  map.connect 'site/advertisers/whitepaper', :controller => 'homepage', :action => 'whitepaper'

  # Login and registration routes
  map.register 'register', :controller => :sign_up, :action => :new
  map.login 'login', :controller => :user_sessions, :action => :new
  map.logout 'logout', :controller => :user_sessions, :action => :destroy
  map.resources :password_resets, :as => 'password-reset', :only => [ :new, :create, :edit, :update ]
  map.resources :internal_devices, :only => [ :index, :show, :destroy, :edit, :update ], :member => { :block => :get }
  map.new_internal_device 'approve_device', :controller => :internal_devices, :action => 'new', :conditions => { :method => :get }
  map.approve_internal_device 'approve_device/:id', :controller => :internal_devices, :action => 'approve', :conditions => { :method => :get }
  
  # Dashboard routes
  map.namespace :account do |account|
    account.resources :whitelist, :controller => 'whitelist', :only => [ :index ], :member => [ :enable, :disable ]
  end  
  map.resources :user_sessions, :only => [ :new, :create, :destroy ]
  map.resources :users, :as => :account, :except => [ :show, :destroy ]
  map.resources :apps, :except => [ :destroy ], :member => { :confirm => :get, :integrate => :get, :publisher_integrate => :get, :archive => :post, :unarchive => :post } do |app|
    app.resources :offers, :only => [ :new, :create, :edit, :update ] , :member => { :toggle => :post, :percentile => :post }, :controller => 'apps/offers' do |offer|
      offer.resources :offer_events, :only => [ :index, :new, :create, :edit, :update, :destroy ], :controller => 'apps/offers/offer_events', :as => :scheduling
    end
    app.resources :currencies, :only => [ :show, :update, :new, :create ],
      :member => { :reset_test_device => :post }, :controller => 'apps/currencies'
    app.resources :virtual_goods, :as => 'virtual-goods', :only => [ :show, :update, :new, :create, :index ],
      :collection => { :reorder => :post }, :controller => 'apps/virtual_goods'
    app.resources :action_offers, :only => [ :new, :create, :edit, :update, :index ], :member => { :toggle => :post }, :collection => { :TJCPPA => :get, :TapjoyPPA => :get }, :controller => 'apps/action_offers'
  end
  map.resources :enable_offer_requests, :only => [ :create ]
  map.resources :reporting, :only => [ :index, :show ], :member => { :export => :post, :download_udids => :get }, :collection => { :aggregate => :get, :export_aggregate => :post, :api => :get, :regenerate_api_key => :post }
  map.resources :billing, :only => [ :index ],
    :collection => { :create_order => :post, :create_transfer => :post, :update_payout_info => :post, :forget_credit_card => :post }
  map.add_funds_billing 'billing/add-funds', :controller => :billing, :action => :add_funds
  map.transfer_funds_billing 'billing/transfer-funds', :controller => :billing, :action => :transfer_funds
  map.payout_info_billing 'billing/payment-info', :controller => :billing, :action => :payout_info
  map.resources :support, :only => [ :index ],
    :collection => { :contact => :post }
  map.resources :statz, :only => [ :index, :show, :edit, :update, :new, :create ],
    :member => { :last_run_times => :get, :udids => :get, :download_udids => :get },
    :collection => { :global => :get, :publisher => :get, :advertiser => :get, :gamez => :get }
  map.resources :activities, :only => [ :index ]
  map.resources :partners, :only => [ :index, :show, :new, :create, :update, :edit ],
    :member => { :make_current => :post, :manage => :post, :stop_managing => :post, :mail_chimp_info => :get, :new_transfer => :get, :create_transfer => :post, :reporting => :get },
    :collection => { :managed_by => :get, :agency_api => :get } do |partner|
    partner.resources :offer_discounts, :only => [ :index, :new, :create ], :member => { :deactivate => :post }, :controller => 'partners/offer_discounts'
    partner.resources :payout_infos, :only => [ :index, :update ]
  end
  map.with_options(:controller => 'search') do |m|
    m.search_offers 'search/offers', :action => 'offers'
    m.search_users 'search/users', :action => 'users'
    m.search_partners 'search/partners', :action => 'partners'
  end
  map.premier 'premier', :controller => :premier, :action => :edit
  
  # Admin tools routes
  map.resources :tools, :only => :index,
    :collection => { :monthly_data => :get, :new_transfer => :get,
                     :money => :get, :failed_sdb_saves => :get, :disabled_popular_offers => :get, :as_groups => :get,
                     :sdb_metadata => :get, :reset_device => :get, :send_currency_failures => :get, :sanitize_users => :get,
                     :resolve_clicks => :post, :sqs_lengths => :get, :elb_status => :get, :ses_status => :get,
                     :publishers_without_payout_info => :get, :publisher_payout_info_changes => :get, :device_info => :get,
                     :freemium_android => :get, :award_currencies => :get, :update_award_currencies => :post},
    :member => {  :edit_android_app => :get, :update_android_app => :post, :update_user_roles => :post}
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
  
  # Additional webserver routes
  map.resources :offer_instructions, :only => [ :index ]
  map.resources :support_requests, :only => [ :new, :create ]
  map.resources :surveys, :only => [ :edit, :create ]
  map.resources :opt_outs, :only => :create
  map.connect 'privacy', :controller => 'homepage', :action => 'privacy'
  map.connect 'privacy.html', :controller => 'homepage', :action => 'privacy'
  
  # Game State routes
  map.with_options :controller => :game_state do |m|
    m.load_game_state 'game_state/load', :action => :load
    m.save_game_state 'game_state/save', :action => :save
  end
  
  # Special paths:
  map.connect 'log_device_app/:action/:id', :controller => 'connect'
  map.connect 'confirm_email_validation', :controller => 'list_signup', :action => 'confirm_api'
  map.connect 'press', :controller => 'homepage/press', :action => 'index'
  map.connect 'press/:id', :controller => 'homepage/press', :action => 'show'
  map.connect 'careers', :controller => 'homepage/careers', :action => 'index'
  map.connect 'careers/:id', :controller => 'homepage/careers', :action => 'show'
  map.connect 'glu', :controller => 'homepage/press', :action => 'glu'
  map.connect 'publishing', :controller => 'homepage', :action => 'publishers'
  map.connect 'androidfund', :controller => 'androidfund'
  map.resources :sdk, :only => [ :index, :show ], :collection => { :popup => :get, :license => :get }
  map.namespace :agency_api do |agency|
    agency.resources :apps, :only => [ :index, :show, :create, :update ]
    agency.resources :partners, :only => [ :index, :show, :create, :update ], :collection => { :link => :post }
    agency.resources :currencies, :only => [ :index, :show, :create, :update ]
  end
  
  ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/legacy.rb'))
  ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/default.rb'))
end
