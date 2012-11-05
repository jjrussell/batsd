Tapjoyad::Application.routes.draw do
  root :to => 'dashboard/homepage#index'
  resources :survey_results, :only => [:new, :create]

  [ 'dashboard', '' ].each do |s|
    namespace :dashboard, :as => nil, :path => s do
      root :to => 'homepage#index'
      match 'team' => 'homepage#team'
      match 'tos-advertiser.html' => 'documents#tos_advertiser'
      match 'tos-publisher.html' => 'documents#tos_publisher'
      match 'publisher-guidelines.html' => 'documents#publisher_guidelines'
      get 'register' => 'sign_up#new', :as => :register
      post 'register' => 'sign_up#create'
      match 'login' => 'user_sessions#new', :as => :login
      match 'logout' => 'user_sessions#destroy', :as => :logout
      resources :password_resets, :only => [:new, :create, :edit, :update]
      match 'password-reset' => 'password_resets#new', :as => :password_reset
      resources :internal_devices, :only => [:index, :show, :destroy, :edit, :update] do
        member do
          get :block, :shallow => true
        end
      end
      match 'approve_device' => 'internal_devices#new', :as => :new_internal_device, :via => :get
      match 'approve_device/:id' => 'internal_devices#approve', :as => :approve_internal_device, :via => :get
      namespace :account do
        resources :whitelist, :only => [:index] do
          collection do
            match :enable
            match :disable
          end
        end
      end
      resources :user_sessions, :only => [:new, :create, :destroy, :index]
      resources :users, :except => [:show, :destroy]
      resources :apps, :except => [:destroy] do
        resource :non_rewarded, :only => [:new, :edit, :create, :update, :show ], :controller => :non_rewarded
        collection do
          get :search
        end
        member do
          get :publisher_integrate
          get :integrate_check
          get :confirm
          post :unarchive
          post :archive
          get :integrate
        end
        resources :offers, :only => [:new, :create, :edit, :update] do
          collection do
            post :toggle
            post :percentile
          end
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
        resources :app_metadatas, :only => [:show, :update, :new, :create] do
          member do
            get :remove
          end
        end
        resources :reengagement_offers do
          collection do
            post :update_status
          end
        end
        resources :push, :only => [:index] do
          collection do
            post :update
          end
        end
        resources :videos, :only => [:index] do
          collection do
            get :options
            put :update_options
          end
        end
      end
      resource :offer do
        member do
          post :toggle
          post :percentile
        end
      end
      resources :offer_creatives, :only => [:show] do
        member do
          get    '/:image_size', :action => :new, :as => :form
          post   '/:image_size', :action => :create
          delete '/:image_size', :action => :destroy
        end
      end
      resources :enable_offer_requests, :only => [:create]
      resources :reporting, :only => [:index, :show] do
        collection do
          get :api
          post :export_aggregate
          get :aggregate
          post :regenerate_api_key
          post ':id' => 'reporting#export'
        end
        member do
          post :export
          get :download_udids
        end

      end

      resources :billing, :only => [:index] do
        collection do
          put :update_payout_info
          post :forget_credit_card
          get :export_statements
          get :export_orders
          post :create_order
          get :export_payouts
          post :create_transfer
          get :export_adjustments
        end

      end

      match 'billing/add-funds' => 'billing#add_funds', :as => :add_funds_billing
      match 'billing/transfer-funds' => 'billing#transfer_funds', :as => :transfer_funds_billing
      match 'billing/payment-info' => 'billing#payout_info', :as => :payout_info_billing
      match 'billing/payment-history' => 'billing#payment_history', :as => :payment_history_billing

      resources :inventory_management, :only => :index do
        collection do
          get :per_app
          post :promoted_offers
          post :partner_promoted_offers
        end
      end
      resources :statz, :only => [:index, :show, :edit, :update, :new, :create] do
        collection do
          get :advertiser
          get :global
          get :publisher
        end
        member do
          get :last_run_times
          get 'last_runs/:udid(/time/:time)', :action => :last_run, :as => :device_last_run
          get :udids
          get :support_request_reward_ratio
          get :show_rate_reasons
          get :download_udids
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
          get :new_dev_credit
          post :set_tapjoy_sponsored
          post :make_current
          post :set_unconfirmed_for_payout
          post :manage
          get :reporting
          post :create_transfer
          post :stop_managing
          post :create_dev_credit
        end
        resources :offer_discounts, :only => [:index, :new, :create] do

          member do
            post :deactivate
          end

        end

      end

      resources :kontagent, :only => [:index, :new, :create, :show, :update]

      match 'partners/managed_by/:id' => 'partners#managed_by'
      match 'partners/by_country/:country' => 'partners#by_country'

      match 'search/gamers' => 'search#gamers', :as => :search_gamers
      match 'search/offers' => 'search#offers', :as => :search_offers
      match 'search/users' => 'search#users', :as => :search_users
      match 'search/partners' => 'search#partners', :as => :search_partners
      match 'search/currencies' => 'search#currencies', :as => :search_currencies
      match 'search/brands' => 'search#brands', :as => :search_brands

      match 'premier' => 'premier#edit', :as => :premier
      resources :survey_results, :only => [:new, :create]
      resources :tools, :only => :index do
        collection do
          post :update_user_roles
          get :fix_rewards
          get :reset_device
          get :publishers_without_payout_info
          get :monthly_data
          get :partner_monthly_balance
          post :recreate_device_identifiers
          post :update_device
          get :send_currency_failures
          get :new_transfer
          get :publisher_payout_info_changes
          get :money
          get :sanitize_users
          post :update_user
          get :device_info
          get :failed_sdb_saves
          post :resolve_clicks
          get :award_currencies
          post :award_currencies
          get :disabled_popular_offers
          get :sqs_lengths
          post :update_award_currencies
          get :sdb_metadata
          get :ses_status
          get :view_pub_user_account
          post :detach_pub_user_account
          get :search_conversion_attempts
          get :view_conversion_attempt
          post :force_conversion
          get :monthly_rev_share_report
          get :download_monthly_rev_share_report
        end
      end


      namespace :tools do

        match 'debug/:bucket' => 'admin_debug#show'

        resources :brands
        resources :experiments do
          member do
            post :conclude
            post :start
          end
        end

        resources :brand_offers, :only => [ :index, :create ] do
          collection do
            post :delete
          end
        end
        resources :currency_approvals, :controller => :approvals, :defaults => { :type => 'currency' }, :only => [:index] do
          collection do
            get :history
            get :mine
          end
          member do
            post :approve, :reject, :assign
          end
        end

        resources :kontagent_approvals, :controller => :approvals, :defaults => { :type => 'KontagentIntegrationRequest' }, :only => [:index] do
          collection do
            get :history
            get :mine
          end
          member do
            post :approve, :reject, :assign
          end
        end

        resources :approvals, :as => :acceptance, :path => 'acceptance', :only => [:index] do
          collection do
            get :history
            get :mine

            get ':type',          :action => :index,   :as => :typed
            get ':type/history',  :action => :history, :as => :typed_history
            get ':type/mine',     :action => :mine,    :as => :typed_mine
          end
          member do
            post :approve
            post :reject
            post :assign
          end
        end
        resources :premier_partners, :only => [:index]
        resources :coupons do
          member do
            put :toggle_enabled
          end
        end
        resources :vouchers, :only => [:show]
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
          resources :video_buttons, :except => [:show]
        end
        resources :offers do
          resources :sales_reps
          collection do
            get :creative
            post :approve_creative
            post :reject_creative
          end
        end
        resources :offer_icons, :only => [ :edit, :create, :update, :destroy ] do
          member do
            put :toggle_auto_update_icon
          end
        end
        resources :payouts, :only => [:index, :create] do
          collection do
            get :export
            post :confirm_payouts
          end
          member do
            get :info
          end
        end
        namespace :resellers do
          resources :payouts, :only => [:index, :create]
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
            delete :delete_photo
            get :wfhs
          end
        end
        resources :offer_lists, :only => [:index]
        resources :optimized_offer_lists, :only => [:index]

        resources :rank_boosts, :except => [:show, :destroy] do
          member do
            post :deactivate
          end
        end
        resources :optimized_rank_boosts, :except => [:show, :destroy] do
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
        resources :recommenders, :only => [:index, :create]
        resources :gamers, :only => [:index, :show] do
          member do
            post :reset_perishable_token
          end
        end
        resources :gamer_devices, :only => [:create, :edit, :new, :show, :update]
        resources :network_costs, :only => [:index]
        resources :partner_program_statz, :only => [:index] do
          collection do
            get :export
          end
        end
        resources :partner_changes, :only => [ :index, :new, :create, :destroy ] do
          member do
            post :complete
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
        resources :wfhs, :only => [:index, :new, :create, :edit, :update, :destroy]
        resources :clients, :only => [:index, :show, :new, :create, :edit, :update] do
          member do
            post :add_partner
            post :remove_partner
          end
        end
        resources :shared_files, :only => [:index, :create] do
          collection do
            post :delete
          end
        end
        resources :partner_validations, :only => [ :index] do
          collection do
            post :confirm_payouts
          end
        end
        resources :cached_offer_lists, :only => [:index, :show]
        resources :rejections, :only => [:index]
        resources :device_ban_lists, :only => [:index, :create]
      end
      resources :ops, :only => :index do
        collection do
          get :as_groups
          get :as_header
          get :as_instances
          get :elb_deregister_instance
          get :ec2_reboot_instance
          get :as_terminate_instance
          get :requests_per_minute
          get :service_stats
          get :elb_status
          get :http_codes
          get :bytes_sent
          get :vertica_status
        end
      end
      match 'mail_chimp_callback/callback' => 'mail_chimp_callback#callback'
      resources :sdk, :only => [:index, :show] do
        collection do
          get :license
          get :popup
        end
      end
    end
  end

  namespace :api do
    namespace :data do
      resources :devices, :only => [:show, :update] do
        collection do
          post :set_last_run_time
        end
      end
      resources :partners, :only => [:show]
      resources :apps, :only => [:show]
      resources :app_metadata, :only => [:show] do
        collection do
          post :increment_or_decrement
        end
      end
      resources :currencies, :only => [:show]
      resources :recommendation_lists, :only => [:new]
      resources :featured_contents do
        collection do
          get :load_featured_content
        end
      end
    end
  end
end
