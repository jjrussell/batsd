ActionController::Routing::Routes.draw do |map|
  map.with_options({:path_prefix => MACHINE_TYPE == 'dashboard' ? '' : 'dashboard', :name_prefix => 'dashboard_'}) do |m|
    m.root :controller => 'dashboard/homepage', :action => :index
  end

  map.connect 'tos-advertiser.html', :controller => 'documents', :action => 'tos_advertiser'
  map.connect 'tos-publisher.html', :controller => 'documents', :action => 'tos_publisher'
  map.connect 'publisher-guidelines.html', :controller => 'documents', :action => 'publisher_guidelines'

  map.resource :sign_up, :controller => :sign_up, :only => :create
  map.register 'register', :controller => :sign_up, :action => :new
  map.login 'login', :controller => :user_sessions, :action => :new
  map.logout 'logout', :controller => :user_sessions, :action => :destroy
  map.resources :password_resets, :as => 'password-reset', :only => [ :new, :create, :edit, :update ]
  map.password_reset 'password-reset', :controller => 'password_resets', :action => :new
  map.resources :internal_devices, :only => [ :index, :show, :destroy, :edit, :update ], :member => { :block => :get }
  map.new_internal_device 'approve_device', :controller => :internal_devices, :action => 'new', :conditions => { :method => :get }
  map.approve_internal_device 'approve_device/:id', :controller => :internal_devices, :action => 'approve', :conditions => { :method => :get }

  map.namespace :account do |account|
    account.resources :whitelist, :controller => 'whitelist', :only => [ :index ], :collection => [ :enable, :disable ]
  end
  map.resources :user_sessions, :only => [ :new, :create, :destroy, :index ]
  map.resources :users, :as => :account, :except => [ :show, :destroy ]
  map.resources :apps, :except => [ :destroy ], :member => { :confirm => :get, :integrate => :get, :publisher_integrate => :get, :integrate_check => :get, :archive => :post, :unarchive => :post }, :collection => { :search => :get } do |app|
    app.resources :offers, :only => [ :new, :create, :edit, :update ] , :member => { :toggle => :post, :percentile => :post }, :controller => 'apps/offers' do |offer|
      offer.resources :offer_events, :only => [ :index, :new, :create, :edit, :update, :destroy ], :controller => 'apps/offers/offer_events', :as => :scheduling
    end
    app.resources :currencies, :only => [ :show, :update, :new, :create ],
      :member => { :reset_test_device => :post }, :controller => 'apps/currencies'
    app.resources :virtual_goods, :as => 'virtual-goods', :only => [ :show, :update, :new, :create, :index ],
      :collection => { :reorder => :post }, :controller => 'apps/virtual_goods'
    app.resources :action_offers, :only => [ :new, :create, :edit, :update, :index ], :member => { :toggle => :post, :preview => :get }, :collection => { :TJCPPA => :get, :TapjoyPPA => :get }, :controller => 'apps/action_offers'
    app.resources :reengagement_offers, :except => [ :show ], :collection => { :update_status => :post }, :controller => 'apps/reengagement_offers'
  end
  map.resources :reengagement_rewards, :only => [ :show ]
  map.with_options :controller => :offer_creatives, :path_prefix => 'offer_creatives/:id', :name_prefix => 'offer_creatives_' do |offer|
    offer.preview '', :action => :show, :conditions => { :method => :get }
    offer.with_options :path_prefix => 'offer_creatives/:id/:image_size' do |s|
      s.form '',    :action => :new, :conditions => { :method => :get }
      s.connect '', :action => :create, :conditions => { :method => :post }
      s.connect '', :action => :destroy, :conditions => { :method => :delete }
    end
  end
  map.resources :enable_offer_requests, :only => [ :create ]
  map.resources :reporting, :only => [ :index, :show ], :member => { :export => :post, :download_udids => :get }, :collection => { :aggregate => :get, :export_aggregate => :post, :api => :get, :regenerate_api_key => :post }
  map.resources :billing, :only => [ :index ],
    :collection => { :create_order => :post, :create_transfer => :post, :update_payout_info => :put, :forget_credit_card => :post, :export_statements => :get, :export_orders => :get, :export_payouts => :get, :export_adjustments => :get }
  map.add_funds_billing 'billing/add-funds', :controller => :billing, :action => :add_funds
  map.transfer_funds_billing 'billing/transfer-funds', :controller => :billing, :action => :transfer_funds
  map.payout_info_billing 'billing/payment-info', :controller => :billing, :action => :payout_info
  map.resources :inventory_management, :only => [ :index ], :collection => { :per_app => :get, :partner_promoted_offers => :post, :promoted_offers => :post }
  map.resources :statz, :only => [ :index, :show, :edit, :update, :new, :create ],
    :member => { :last_run_times => :get, :udids => :get, :download_udids => :get, :support_request_reward_ratio => :get },
    :collection => { :global => :get, :publisher => :get, :advertiser => :get }
  map.resources :activities, :only => [ :index ]
  map.resources :partners, :only => [ :index, :show, :new, :create, :update, :edit ],
    :member => { :make_current => :post, :manage => :post, :stop_managing => :post, :mail_chimp_info => :get, :new_transfer => :get, :create_transfer => :post, :reporting => :get, :set_tapjoy_sponsored => :post, :set_unconfirmed_for_payout => :post },
    :collection => { :agency_api => :get } do |partner|
    partner.resources :offer_discounts, :only => [ :index, :new, :create ], :member => { :deactivate => :post }, :controller => 'partners/offer_discounts'
    partner.resources :payout_infos, :only => [ :index, :update ]
  end
  map.connect 'partners/managed_by/:id', :controller => :partners, :action => :managed_by
  map.with_options(:controller => 'search') do |m|
    m.search_gamers 'search/gamers', :action => 'gamers'
    m.search_offers 'search/offers', :action => 'offers'
    m.search_users 'search/users', :action => 'users'
    m.search_partners 'search/partners', :action => 'partners'
    m.search_currencies 'search/currencies', :action => 'currencies'
  end
  map.premier 'premier', :controller => :premier, :action => :edit
  map.resources :survey_results, :only => [ :new, :create ]

  # Admin tools routes
  map.resources :tools, :only => :index,
    :collection => { :monthly_data => :get, :new_transfer => :get,
                     :money => :get, :failed_sdb_saves => :get, :disabled_popular_offers => :get,
                     :sdb_metadata => :get, :reset_device => :get, :send_currency_failures => :get, :sanitize_users => :get,
                     :resolve_clicks => :post, :sqs_lengths => :get, :ses_status => :get,
                     :publishers_without_payout_info => :get, :publisher_payout_info_changes => :get, :device_info => :get,
                     :award_currencies => :post, :update_award_currencies => :post,
                     :update_user_roles => :post, :update_device => :post, :fix_rewards => :get }

  map.namespace :tools do |tools|
    tools.resources :approvals, :as => 'acceptance', :only => [:index], :collection => [:history, :mine], :member => [:approve, :reject, :assign]
    tools.with_options(:controller => 'approvals') do |a|
      a.typed_approvals         'acceptance/:type',          :action => :index
      a.history_typed_approvals 'acceptance/:type/history',  :action => :history
      a.mine_typed_approvals    'acceptance/:type/mine',     :action => :mine
    end

    tools.resources :premier_partners, :only => [ :index ]
    tools.resources :generic_offers, :only => [ :index, :new, :create, :edit, :update ]
    tools.resources :orders, :only => [ :new, :create ],
      :member => { :mark_invoiced => :put, :retry_invoicing => :put },
      :collection => { :failed_invoices => :get }
    tools.resources :video_offers, :only => [ :new, :create, :edit, :update ] do |video_offer|
      video_offer.resources :video_buttons, :controller => 'video_offers/video_buttons'
    end
    tools.resources :offers,
      :collection => { :creative => :get, :approve_creative => :post, :reject_creative => :post }
    tools.resources :payouts, :only => [ :index, :create ], :member => { :info => :get }, :collection => { :confirm_payouts => :post, :export => :get }
    tools.resources :enable_offer_requests, :only => [ :update, :index ]
    tools.resources :admin_devices, :only => [ :index, :new, :create, :edit, :update, :destroy ]
    tools.resources :offer_events, :only => [ :index, :new, :create, :edit, :update, :destroy ], :as => :scheduling
    tools.resources :users, :only  => [ :index, :show] do |user|
      user.resources :role_assignments, :only => [ :create, :destroy ], :controller => 'users/role_assignments'
      user.resources :partner_assignments, :only => [ :create, :destroy ], :controller => 'users/partner_assignments'
    end
    tools.resources :employees, :only => [ :index, :new, :create, :edit, :update ], :member => [ :delete_photo, :wfhs ]
    tools.resources :offer_lists, :only => [ :index ]
    tools.resources :rank_boosts, :except => [ :show, :destroy ], :member => { :deactivate => :post }
    tools.resources :external_publishers, :only => [ :index, :update ]
    tools.resources :jobs, :except => [ :show ]
    tools.resources :earnings_adjustments, :only => [ :new, :create ]
    tools.resources :editors_picks, :except => [ :destroy ], :member => { :activate => :post, :expire => :post }
    tools.resources :app_reviews, :except => [ :show ]
    tools.resources :featured_contents, :except => [ :show ]
    tools.resources :agency_users, :only => [ :index, :show ]
    tools.resources :support_requests, :only => [ :index ], :collection => { :mass_resolve => [ :get, :post ] }
    tools.resources :press_releases, :only => [ :index, :new, :create, :edit, :update ]
    tools.resources :recommenders, :only => [ :index, :create ]
    tools.resources :gamers, :only => [ :index, :show ]
    tools.resources :gamer_devices, :only => [ :create, :edit, :new, :show, :update ]
    tools.resources :network_costs, :only => [ :index, :new, :create ]
    tools.resources :partner_program_statz, :only => [ :index ], :collection => { :export => :get }
    tools.resources :survey_offers, :except => [ :show ], :member => { :toggle_enabled => :put }
    tools.resources :payout_freezes, :only => [ :index, :create ], :member => { :disable => :post }
    tools.resources :currency_approvals, :only => [:index], :collection => [:mine, :history], :member => [:approve, :reject, :assign], :controller => :approvals, :requirements => { :type => :currency, :calling_controller => 'tools/currency_approvals' }
    tools.resources :wfhs, :only => [ :index, :new, :create, :edit, :update, :destroy ]
    tools.resources :clients, :only => [ :index, :show, :new, :create, :edit, :update], :member => { :add_partner => :post, :remove_partner => :post }
    tools.resources :shared_files, :only => [ :index, :create ], :collection => { :delete => :post }
  end

  # Operations tools routes
  map.resources :ops, :only => :index,
    :collection => {
      :as_groups => :get,
      :as_header => :get,
      :as_instances => :get,
      :elb_deregister_instance => :get,
      :ec2_reboot_instance => :get,
      :as_terminate_instance => :get,
      :service_stats => :get,
      :elb_status => :get,
      :http_codes => :get,
      :bytes_sent => :get,
    }

  map.connect 'mail_chimp_callback/callback', :controller => :mail_chimp_callback, :action => :callback
end
