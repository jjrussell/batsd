Tapjoyad::Application.routes.draw do
  match 'connect' => 'connect#index'
  match 'healthz' => 'healthz#index'

  resources :apps_installed
  resource :clicks, :controller => :click do
    match :app
    match :reengagement
    match :action
    match :generic
    match :rating
    match :video
    match :survey
    match :test_offer
    match :test_video_offer
  end
  resources :display_ad, :only => [:index], :controller => :display_ad do
    collection do
      match :webview
      match :image
    end
  end
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
  resources :offer_instructions, :only => [:index]
  resources :offer_completed do
    collection do
      match :boku
      match :gambit
      match :paypal
      match :socialvibe
    end
  end
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
  resources :support_requests, :only => [:new, :create]
  resources :tools_surveys, :only => [:edit, :create]

  resources :videos, :only => [:index] do
    member do
      get :complete
    end
    match 'privacy' => 'documents#privacy'
    match 'privacy.html' => 'documents#privacy'
    match 'game_state/load' => 'game_state#load', :as => :load_game_state
    match 'game_state/save' => 'game_state#save', :as => :save_game_state
    match 'log_device_app/:action/:id' => 'connect#index'
    match 'confirm_email_validation' => 'list_signup#confirm_api'
  end

  namespace :job do
    match 'master_calculate_next_payout' => 'master_calculate_next_payout#index'
    resources 'master_reload_statz', :only => :index do
      collection do
        match :daily
        match :partner_index
        match :partner_daily
      end
    end
    match 'queue_conversion_tracking' => 'queue_conversion_tracking#run_job'
    match 'queue_send_currency' => 'queue_send_currency#run_job'
  end

end
