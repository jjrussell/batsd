Tapjoyad::Application.routes.draw do
  match 'connect' => 'connect#index'
  match 'healthz' => 'healthz#index'
  match 'log_device_app' => 'connect#index'
  match 'Connect' => 'connect#index'
  match 'set_publisher_user_id' => 'set_publisher_user_id#index'
  match 'get_ad_order' => 'get_ad_order#index'

  resources :apps_installed
  resource :click, :controller => :click do
    get :app
    get :reengagement
    get :action
    get :deeplink
    get :generic
    get :rating
    get :video
    get :survey
    get :test_offer
    get :test_video_offer
  end
  # TODO: make display_ad routes better
  match 'display_ad(/index)' => 'display_ad#index', :defaults => { :format => 'xml'}
  match 'display_ad/webview' => 'display_ad#webview'
  match 'display_ad/image'   => 'display_ad#image'
  resources :fullscreen_ad, :only => [:index], :controller => :fullscreen_ad do
    collection do
      match :test_offer
      match :test_video_offer
    end
  end
  resources :get_offers, :only => [:index] do
    collection do
      match :webpage
      match :featured
    end
  end
  match 'get_vg_store_items/all' => 'get_vg_store_items#all'
  match 'get_vg_store_items/purchased' => 'get_vg_store_items#purchased'
  match 'get_vg_store_items/user_account' => 'get_vg_store_items#user_account'
  resources :offer_instructions, :only => [:index]

  match 'offer_completed' => 'offer_completed#index'
  match 'offer_completed/boku' => 'offer_completed#boku'
  match 'offer_completed/gambit' => 'offer_completed#gambit'
  match 'offer_completed/paypal' => 'offer_completed#paypal'
  match 'offer_completed/socialvibe' => 'offer_completed#socialvibe'

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
  resources :tools_surveys, :only => [:edit, :create]

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
end
