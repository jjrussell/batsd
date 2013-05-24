
Tapjoyad::Application.routes.draw do
  match 'connect' => 'connect#index'
  match 'healthz' => 'healthz#index'
  match 'log_device_app' => 'connect#index'
  match 'Connect' => 'connect#index'
  match 'set_publisher_user_id' => 'set_publisher_user_id#index'
  match 'get_ad_order' => 'get_ad_order#index'
  match 'package_names' => 'package_names#index'
  resources :apps_installed
  resource :click, :controller => :click do
    match :app
    match :reengagement
    match :action
    match :deeplink
    match :generic
    match :rating
    match :video
    match :survey
    match :test_offer
    match :test_video_offer
    match :coupon
  end
  # TODO: make display_ad routes better
  match 'display_ad(/index)' => 'display_ad#index', :defaults => { :format => 'xml'}
  match 'display_ad/cross_promo' => 'display_ad#cross_promo', :defaults => { :format => 'xml'}
  match 'display_ad/webview' => 'display_ad#webview'
  match 'display_ad/image'   => 'display_ad#image'
  match 'impression'         => 'impression#index'
  resource :fullscreen_ad, :only => [:index], :controller => :fullscreen_ad do
    collection do
      match :index
      post  :skip
      match :test_offer
      match :test_video_offer
    end
  end
  resources :get_offers, :only => [:index] do
    ['', '_cross_promo'].each do |s|
      collection do
        match "webpage#{s}".to_sym
        match "featured#{s}".to_sym
      end
    end
  end
  match 'get_vg_store_items/all' => 'get_vg_store_items#all'
  match 'get_vg_store_items/purchased' => 'get_vg_store_items#purchased'
  match 'get_vg_store_items/user_account' => 'get_vg_store_items#user_account'
  resources :offer_instruction_click, :only => [:index]
  resources :offer_instructions, :only => [:index] do
    collection do
      get :app_not_installed
    end
  end
  resources :offer_age_gating, :only => [:index] do
    collection do
      get :redirect_to_click
      get :redirect_to_get_offers
    end
  end
  resources :coupon_instructions, :only => [:new, :create]

  match 'offer_triggered_actions/fb_visit' => 'offer_triggered_actions#fb_visit'
  match 'offer_triggered_actions/fb_login' => 'offer_triggered_actions#fb_login'
  match 'offer_triggered_actions/load_app' => 'offer_triggered_actions#load_app'

  match 'offer_completed' => 'offer_completed#index'
  match 'offer_completed/boku' => 'offer_completed#boku'
  match 'offer_completed/gambit' => 'offer_completed#gambit'
  match 'offer_completed/paypal' => 'offer_completed#paypal'
  match 'offer_completed/socialvibe' => 'offer_completed#socialvibe'
  match 'offer_completed/adility' => 'offer_completed#adility'

  resource :points do
    collection do
      match :award
      match :spend
      match :purchase_vg
      match :consume_vg
    end
  end
  resources :reengagement_rewards, :only => [:index]
  resources :survey_results, :only => [:new, :create]
  resources :support_requests, :only => [:new, :create] do
    collection do
      get :incomplete_offers
    end
  end
  resources :user_events, :only => [:create]

  resources :videos, :only => [:index] do
    member do
      get :complete
    end
  end

  match 'coupons/complete' => 'coupons#complete', :as => :coupon_complete
  match 'game_state/load' => 'game_state#load', :as => :load_game_state
  match 'game_state/save' => 'game_state#save', :as => :save_game_state
  match 'log_device_app/:action/:id' => 'connect#index'

  namespace :job do
    match 'master_calculate_next_payout' => 'master_calculate_next_payout#index'
    resources 'master_reload_statz', :only => :index do
      collection do
        match :daily
        match :partner_index
        match :partner_daily
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
      resources :in_network_apps do
        collection do
          get :search
        end
      end
    end
  end
end
