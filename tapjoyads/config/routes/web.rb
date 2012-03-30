Tapjoyad::Application.routes.draw do
  match 'healthz' => 'healthz#index'

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
    match 'privacy' => 'documents#privacy'
    match 'privacy.html' => 'documents#privacy'
    match 'game_state/load' => 'game_state#load', :as => :load_game_state
    match 'game_state/save' => 'game_state#save', :as => :save_game_state
    match 'log_device_app/:action/:id' => 'connect#index'
    match 'confirm_email_validation' => 'list_signup#confirm_api'
  end

end
