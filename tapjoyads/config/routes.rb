Tapjoyad::Application.routes.draw do
  match 'healthz' => 'healthz#index'
  namespace :agency_api do
    resources :apps, :only => [:index, :show, :create, :update]
    resources :partners, :only => [:index, :show, :create, :update] do
      collection do
        post :link
      end


    end
    resources :currencies, :only => [:index, :show, :create, :update]
  end

  resources :reporting_data, :only => :index do
    collection do
      get :udids
    end


  end

  match 'adways_data' => 'adways_data#index'
  match 'brooklyn_packet_data' => 'brooklyn_packet_data#index'
  match 'ea_data' => 'ea_data#index'
  match 'fluent_data' => 'fluent_data#index'
  match 'glu_data' => 'glu_data#index'
  match 'gogii_data' => 'gogii_data#index'
  match 'loopt_data' => 'loopt_data#index'
  match 'ngmoco_data' => 'ngmoco_data#index'
  match 'pinger_data' => 'pinger_data#index'
  match 'pocketgems_data' => 'pocketgems_data#index'
  match 'sgn_data' => 'sgn_data#index'
  match 'zynga_data' => 'zynga_data#index'
  match 'tapulous_marketing' => 'tapulous_marketing#index'
  match 'tos-advertiser.html' => 'documents#tos_advertiser'
  match 'tos-publisher.html' => 'documents#tos_publisher'
  match 'publisher-guidelines.html' => 'documents#publisher_guidelines'
  resource :sign_up, :only => :create
  match 'register' => 'sign_up#new', :as => :register
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout
  resources :password_resets, :only => [:new, :create, :edit, :update]
  match 'password-reset' => 'password_resets#new', :as => :password_reset
  resources :internal_devices, :only => [:index, :show, :destroy, :edit, :update] do

    member do
      get :block
    end

  end

  match 'approve_device' => 'internal_devices#new', :as => :new_internal_device, :via => :get
  match 'approve_device/:id' => 'internal_devices#approve', :as => :approve_internal_device, :via => :get
  namespace :account do
    resources :whitelist, :only => [:index] do
      collection do
        :enable
        :disable
      end


    end
  end

  resources :user_sessions, :only => [:new, :create, :destroy, :index]
  resources :users, :except => [:show, :destroy]
  resources :apps, :except => [:destroy] do
    collection do
      get :search
    end
    member do
      post :unarchive
      get :confirm
      get :integrate
      get :publisher_integrate
      get :integrate_check
      post :archive
    end
    resources :offers, :only => [:new, :create, :edit, :update] do

      member do
        post :toggle
        post :percentile
      end
      resources :offer_events, :only => [:index, :new, :create, :edit, :update, :destroy]
    end

    resources :currencies, :only => [:show, :update, :new, :create] do

      member do
        post :reset_test_device
      end

    end

    resources :virtual_goods, :only => [:show, :update, :new, :create, :index] do
      collection do
        post :reorder
      end


    end

    resources :action_offers, :only => [:new, :create, :edit, :update, :index] do
      collection do
        get :TJCPPA
        get :TapjoyPPA
      end
      member do
        get :preview
        post :toggle
      end

    end

    resources :reengagement_offers, :except => [:show] do
      collection do
        post :update_status
      end


    end
  end

  resources :reengagement_rewards, :only => [:show]
  #match '' => 'offer_creatives#show', :as => :preview, :path_prefix => 'offer_creatives/:id', :name_prefix => 'offer_creatives_', :via => :get
  #match '' => 'offer_creatives#new', :as => :form, :path_prefix => 'offer_creatives/:id/:image_size', :name_prefix => 'offer_creatives_', :via => :get
  #match '' => 'offer_creatives#create', :path_prefix => 'offer_creatives/:id/:image_size', :name_prefix => 'offer_creatives_', :via => :post
  #match '' => 'offer_creatives#destroy', :path_prefix => 'offer_creatives/:id/:image_size', :name_prefix => 'offer_creatives_', :via => :delete
  resources :enable_offer_requests, :only => [:create]
  resources :reporting, :only => [:index, :show] do
    collection do
      post :export_aggregate
      get :api
      post :regenerate_api_key
      get :aggregate
    end
    member do
      get :download_udids
      post :export
    end

  end

  resources :billing, :only => [:index] do
    collection do
      get :export_adjustments
      put :update_payout_info
      post :forget_credit_card
      get :export_statements
      get :export_orders
      post :create_order
      get :export_payouts
      post :create_transfer
    end


  end

  match 'billing/add-funds' => 'billing#add_funds', :as => :add_funds_billing
  match 'billing/transfer-funds' => 'billing#transfer_funds', :as => :transfer_funds_billing
  match 'billing/payment-info' => 'billing#payout_info', :as => :payout_info_billing
  resources :statz, :only => [:index, :show, :edit, :update, :new, :create] do
    collection do
      get :publisher
      get :advertiser
      get :global
    end
    member do
      get :last_run_times
      get :support_request_reward_ratio
      get :download_udids
      get :udids
    end

  end

  resources :activities, :only => [:index]
  resources :partners, :only => [:index, :show, :new, :create, :update, :edit] do
    collection do
      get :agency_api
    end
    member do
      get :mail_chimp_info
      get :new_transfer
      post :set_tapjoy_sponsored
      get :reporting
      post :make_current
      post :set_unconfirmed_for_payout
      post :manage
      post :create_transfer
      post :stop_managing
    end
    resources :offer_discounts, :only => [:index, :new, :create] do

      member do
        post :deactivate
      end

    end

    resources :payout_infos, :only => [:index, :update]
  end

  match 'partners/managed_by/:id' => 'partners#managed_by'
  match 'search/gamers' => 'search#gamers', :as => :search_gamers
  match 'search/offers' => 'search#offers', :as => :search_offers
  match 'search/users' => 'search#users', :as => :search_users
  match 'search/partners' => 'search#partners', :as => :search_partners
  match 'premier' => 'premier#edit', :as => :premier
  resources :survey_results, :only => [:new, :create]
  resources :tools, :only => :index do
    collection do
      get :publishers_without_payout_info
      get :monthly_data
      post :update_device
      get :send_currency_failures
      get :publisher_payout_info_changes
      get :money
      get :sanitize_users
      get :new_transfer
      get :device_info
      get :failed_sdb_saves
      post :resolve_clicks
      post :award_currencies
      get :disabled_popular_offers
      get :sqs_lengths
      post :update_award_currencies
      get :sdb_metadata
      get :ses_status
      post :update_user_roles
      get :reset_device
    end


  end

  namespace :tools do
    resources :approvals, :only => [:index] do
      collection do
        :history
        :mine
      end
      member do
        :approve
        :reject
        :assign
      end

    end
    resources :premier_partners, :only => [:index]
    resources :generic_offers, :only => [:index, :new, :create, :edit, :update]
    resources :orders, :only => [:new, :create] do
      collection do
        get :failed_invoices
      end
      member do
        put :mark_invoiced
        put :retry_invoicing
      end

    end
    resources :video_offers, :only => [:new, :create, :edit, :update] do


      resources :video_buttons
    end
    resources :offers do
      collection do
        post :reject_creative
        get :creative
        post :approve_creative
      end


    end
    resources :payouts, :only => [:index, :create] do
      collection do
        post :confirm_payouts
        get :export
      end
      member do
        get :info
      end

    end
    resources :enable_offer_requests, :only => [:update, :index]
    resources :admin_devices, :only => [:index, :new, :create, :edit, :update, :destroy]
    resources :offer_events, :only => [:index, :new, :create, :edit, :update, :destroy]
    resources :users, :only => [:index, :show] do


      resources :role_assignments, :only => [:create, :destroy]
      resources :partner_assignments, :only => [:create, :destroy]
    end
    resources :employees, :only => [:index, :new, :create, :edit, :update] do

      member do
        :delete_photo
        :wfhs
      end

    end
    resources :offer_lists, :only => [:index]
    resources :rank_boosts, :except => [:show, :destroy] do

      member do
        post :deactivate
      end

    end
    resources :external_publishers, :only => [:index, :update]
    resources :jobs, :except => [:show]
    resources :earnings_adjustments, :only => [:new, :create]
    resources :editors_picks, :except => [:destroy] do

      member do
        post :activate
        post :expire
      end

    end
    resources :app_reviews, :except => [:show]
    resources :featured_contents, :except => [:show]
    resources :agency_users, :only => [:index, :show]
    resources :support_requests, :only => [:index] do
      collection do
        get :mass_resolve
        post :mass_resolve
      end


    end
    resources :press_releases, :only => [:index, :new, :create, :edit, :update]
    resources :recommenders, :only => [:index, :create]
    resources :gamers, :only => [:index, :show]
    resources :gamer_devices, :only => [:create, :edit, :new, :show, :update]
    resources :network_costs, :only => [:index, :new, :create]
    resources :partner_program_statz, :only => [:index] do
      collection do
        get :export
      end


    end
    resources :survey_offers, :except => [:show] do

      member do
        put :toggle_enabled
      end

    end
    resources :payout_freezes, :only => [:index, :create] do

      member do
        post :disable
      end

    end
    resources :currency_approvals, :only => [:index] do
      collection do
        :mine
        :history
      end
      member do
        :approve
        :reject
        :assign
      end

    end
    resources :wfhs, :only => [:index, :new, :create, :edit, :update, :destroy]
    resources :clients, :only => [:index, :show, :new, :create, :edit, :update] do

      member do
        post :add_partner
        post :remove_partner
      end

    end
  end

  resources :ops, :only => :index do
    collection do
      get :http_codes
      get :as_groups
      get :service_stats
      get :elb_status
    end


  end

  match 'mail_chimp_callback/callback' => 'mail_chimp_callback#callback'
  match 'assets/*filename' => 'sprocket#show', :as => :assets
  match '/games' => 'games/homepage#index', :path_prefix => 'games', :name_prefix => 'games_'
  namespace :games do
    match 'tos' => 'games/homepage#tos', :as => :tos, :path_prefix => 'games', :name_prefix => 'games_'
    match 'privacy' => 'games/homepage#privacy', :as => :privacy, :path_prefix => 'games', :name_prefix => 'games_'
    match 'help' => 'games/homepage#help', :as => :help, :path_prefix => 'games', :name_prefix => 'games_'
    match 'switch_device' => 'games/homepage#switch_device', :as => :switch_device, :path_prefix => 'games', :name_prefix => 'games_'
    match 'send_device_link' => 'games/homepage#send_device_link', :as => :send_device_link, :path_prefix => 'games', :name_prefix => 'games_'
    match 'earn/:eid' => 'games/homepage#earn', :as => :earn
    match 'more_apps' => 'games/homepage#index', :as => :more_apps, :path_prefix => 'games', :name_prefix => 'games_'
    match 'get_app' => 'games/homepage#get_app', :as => :get_app, :path_prefix => 'games', :name_prefix => 'games_'
    match 'editor_picks' => 'games/more_games#editor_picks', :as => :more_games_editor_picks, :path_prefix => 'games', :name_prefix => 'games_'
    match 'recommended' => 'games/more_games#recommended', :as => :more_games_recommended, :path_prefix => 'games', :name_prefix => 'games_'
    match 'translations' => 'games/homepage#translations', :as => :translations, :path_prefix => 'games', :name_prefix => 'games_'
    resources :my_apps, :only => [:show, :index]
    resources :gamer_sessions, :only => [:new, :create, :destroy, :index]
    match 'login' => 'games/gamer_sessions#create', :path_prefix => 'games', :name_prefix => 'games_', :via => :post
    match 'login' => 'games/gamer_sessions#new', :as => :login, :path_prefix => 'games', :name_prefix => 'games_'
    match 'logout' => 'games/gamer_sessions#destroy', :as => :logout, :path_prefix => 'games', :name_prefix => 'games_'
    match 'support' => 'games/support_requests#new', :type => 'contact_support'
    match 'bugs' => 'games/support_requests#new', :type => 'report_bug'
    match 'feedback' => 'games/support_requests#new', :type => 'feedback'
    resource :gamer, :only => [:create, :edit, :update, :destroy, :show, :new] do

      member do
        get :prefs
        put :update_password
        get :password
        put :accept_tos
        get :confirm_delete
      end
      resource :device, :only => [:new, :create] do

        member do
          get :finalize
        end

      end

      resource :favorite_app, :only => [:create, :destroy]
      resource :gamer_profile, :only => [:update] do

        member do
          put :update_prefs
          put :dissociate_account
          put :update_birthdate
        end

      end
    end

    resources :gamer_profile, :only => [:show, :edit, :update]
    match 'register' => 'games/gamers#new', :as => :register, :path_prefix => 'games', :name_prefix => 'games_'
    resources :confirmations, :only => [:create]
    match 'confirm' => 'games/confirmations#create', :as => :confirm, :path_prefix => 'games', :name_prefix => 'games_'
    resources :password_resets, :only => [:new, :create, :edit, :update]
    match 'password-reset' => 'password_resets#new', :as => :password_reset
    resources :support_requests, :only => [:new, :create]
    resources :android
    resources :social, :only => [:index]
    namespace :social do
      match 'invite_email_friends' => 'games/social#invite_email_friends', :as => :invite_email_friends
      match 'connect_facebook_account' => 'games/social#connect_facebook_account', :as => :connect_facebook_account
      match 'send_email_invites' => 'games/social#send_email_invites', :as => :send_email_invites
      match 'invite_twitter_friends' => 'games/social#invite_twitter_friends', :as => :invite_twitter_friends
      match 'send_twitter_invites' => 'games/social#send_twitter_invites', :as => :send_twitter_invites
      match 'get_twitter_friends' => 'games/social#get_twitter_friends', :as => :get_twitter_friends
      match 'invites' => 'games/social#invites', :as => :invites
      match 'friends' => 'games/social#friends', :as => :friends
      namespace :twitter do
        match 'start_oauth' => 'games/social/twitter#start_oauth', :as => :start_oauth
        match 'finish_oauth' => 'games/social/twitter#finish_oauth', :as => :finish_oauth
      end
    end
    resources :survey_results, :only => [:new, :create]
    resources :app_reviews, :only => [:index, :create, :edit, :update, :new, :destroy]
  end

  match 'service1.asmx/Connect' => 'connect#index'
  match 'Service1.asmx/Connect' => 'connect#index'
  match 'service1.asmx/AdShown' => 'adshown#index'
  match 'Service1.asmx/AdShown' => 'adshown#index'
  match 'service1.asmx/SubmitTapjoyAdClick' => 'submit_click#ad'
  match 'Service1.asmx/SubmitTapjoyAdClick' => 'submit_click#ad'
  match 'service1.asmx/SubmitAppStoreClick' => 'submit_click#store'
  match 'Service1.asmx/SubmitAppStoreClick' => 'submit_click#store'
  match 'service1.asmx/GetAppIcon' => 'get_app_image#icon'
  match 'Service1.asmx/GetAppIcon' => 'get_app_image#icon'
  match 'service1.asmx/GetOffersForPublisherCurrencyByType' => 'get_offers#index'
  match 'Service1.asmx/GetOffersForPublisherCurrencyByType' => 'get_offers#index'
  match 'service1.asmx/GetTapjoyAd' => 'getad#index'
  match 'Service1.asmx/GetTapjoyAd' => 'getad#index'
  match 'service1.asmx/GetAdOrder' => 'get_ad_order#index'
  match 'Service1.asmx/GetAdOrder' => 'get_ad_order#index'
  match 'service1.asmx/SubmitOfferClick' => 'submit_click#offer'
  match 'Service1.asmx/SubmitOfferClick' => 'submit_click#offer'
  match 'service1.asmx/GetUserOfferStatus' => 'offer_status#index'
  match 'Service1.asmx/GetUserOfferStatus' => 'offer_status#index'
  match 'service1.asmx/GetAllVGStoreItems' => 'get_vg_store_items#all'
  match 'Service1.asmx/GetAllVGStoreItems' => 'get_vg_store_items#all'
  match 'service1.asmx/GetPurchasedVGStoreItems' => 'get_vg_store_items#purchased'
  match 'Service1.asmx/GetPurchasedVGStoreItems' => 'get_vg_store_items#purchased'
  match 'service1.asmx/GetUserAccountObject' => 'get_vg_store_items#user_account'
  match 'Service1.asmx/GetUserAccountObject' => 'get_vg_store_items#user_account'
  match 'service1.asmx/PurchaseVGWithCurrency' => 'points#purchase_vg'
  match 'Service1.asmx/PurchaseVGWithCurrency' => 'points#purchase_vg'
  match 'service1.asmx/:action' => 'rackspace#index'
  match 'Service1.asmx/:action' => 'rackspace#index'
  match 'TapDefenseCurrencyService.asmx/:action' => 'rackspace#index'
  match 'TapPointsCurrencyService.asmx/:action' => 'rackspace#index'
  match 'RingtoneService.asmx/:action' => 'rackspace#index'
  match 'AppRedir.aspx/:action' => 'rackspace#index'
  match 'Redir.aspx/:action' => 'rackspace#index'
  match 'RateApp.aspx/:action' => 'rackspace#index'
  match 'Offers.aspx/:action' => 'rackspace#index'
  match 'purchase_vg' => 'points#purchase_vg'
  match 'purchase_vg/spend' => 'points#spend'
  resources :sdk, :only => [:index, :show] do
    collection do
      get :popup
      get :license
    end


  end

  resources :offer_instructions, :only => [:index]
  resources :support_requests, :only => [:new, :create]
  resources :tools_surveys, :only => [:edit, :create]
  resources :survey_results, :only => [:new, :create]
  resources :opt_outs, :only => :create
  resources :reengagement_rewards, :only => [:index]
  resources :videos, :only => [:index] do

    member do
      get :complete
    end

  end

  match 'privacy' => 'documents#privacy'
  match 'privacy.html' => 'documents#privacy'
  match 'game_state/load' => 'game_state#load', :as => :load_game_state
  match 'game_state/save' => 'game_state#save', :as => :save_game_state
  match 'log_device_app/:action/:id' => 'connect#index'
  match 'confirm_email_validation' => 'list_signup#confirm_api'
  match '/' => 'homepage#start'
  match 'site/privacy' => 'documents#privacy'
  match 'site/privacy.html' => 'documents#privacy'
  match 'site/privacy_mobile' => 'documents#privacy_mobile'
  match 'site/:action' => 'homepage#index'
  match 'index.html' => 'homepage#index_redirect'
  match 'site/advertisers/whitepaper' => 'homepage#whitepaper'
  match 'press' => 'homepage/press#index'
  match 'press/:id' => 'homepage/press#show'
  match 'careers' => 'homepage/careers#index'
  match 'careers/:id' => 'homepage/careers#show'
  match 'glu' => 'homepage/press#glu'
  match 'publishing' => 'homepage#publishers'
  match 'androidfund' => 'androidfund#index'
  match 'AndroidFund' => 'androidfund#index'
  match 'androidfund/apply' => 'androidfund#apply'
  match 'privacy' => 'documents#privacy'
  match 'privacy.html' => 'documents#privacy'
  resources :opt_outs, :only => :create
  match ':controller(/:action(/:id))'

  root :to => 'dashboard/homepage#index'
end
