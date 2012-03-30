Tapjoyad::Application.routes.draw do
  root :to => 'homepage#start'
  match 'assets/*filename' => 'sprocket#show', :as => :assets
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
  namespace :games do
    match '/' => 'games/homepage#index'
    match 'tos' => 'games/homepage#tos', :as => :tos
    match 'privacy' => 'games/homepage#privacy', :as => :privacy
    match 'help' => 'games/homepage#help', :as => :help
    match 'switch_device' => 'games/homepage#switch_device', :as => :switch_device
    match 'send_device_link' => 'games/homepage#send_device_link', :as => :send_device_link
    match 'earn/:id' => 'games/homepage#earn', :as => :earn
    match 'more_apps' => 'games/homepage#index', :as => :more_apps
    match 'get_app' => 'games/homepage#get_app', :as => :get_app
    match 'editor_picks' => 'games/more_games#editor_picks', :as => :more_games_editor_picks
    match 'recommended' => 'games/more_games#recommended', :as => :more_games_recommended
    match 'translations' => 'games/homepage#translations', :as => :translations
    resources :my_apps, :only => [:show, :index]
    resources :gamer_sessions, :only => [:new, :create, :destroy, :index]
    get 'login' => 'games/gamer_sessions#new', :as => :login
    post 'login' => 'games/gamer_sessions#create'
    match 'logout' => 'games/gamer_sessions#destroy', :as => :logout
    match 'support' => 'games/support_requests#new', :type => 'contact_support'
    match 'bugs' => 'games/support_requests#new', :type => 'report_bug'
    match 'feedback' => 'games/support_requests#new', :type => 'feedback'
    resource :gamer, :only => [:create, :edit, :update, :destroy, :show, :new] do
      member do
        put :update_password
        put :accept_tos
        get :password
        get :confirm_delete
        get :prefs
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
    match 'register' => 'games/gamers#new', :as => :register
    resources :confirmations, :only => [:create]
    match 'confirm' => 'games/confirmations#create', :as => :confirm
    resources :password_resets, :only => [:new, :create, :edit, :update]
    match 'password-reset' => 'games/password_resets#new', :as => :password_reset
    resources :support_requests, :only => [:new, :create]
    resources :android
    resources :social, :only => [:index]
    match 'invite_email_friends' => 'games/social#invite_email_friends', :as => :invite_email_friends
    match 'social/connect_facebook_account' => 'games/social#connect_facebook_account', :as => :connect_facebook_account
    match 'send_email_invites' => 'games/social#send_email_invites', :as => :send_email_invites
    match 'invite_twitter_friends' => 'games/social#invite_twitter_friends', :as => :invite_twitter_friends
    match 'send_twitter_invites' => 'games/social#send_twitter_invites', :as => :send_twitter_invites
    match 'get_twitter_friends' => 'games/social#get_twitter_friends', :as => :get_twitter_friends
    match 'social/invites' => 'games/social#invites', :as => :invites
    match 'social/friends' => 'games/social#friends', :as => :friends
    match 'twitter/start_oauth' => 'games/social/twitter#start_oauth', :as => :start_oauth
    match 'twitter/finish_oauth' => 'games/social/twitter#finish_oauth', :as => :finish_oauth
    resources :survey_results, :only => [:new, :create]
    resources :app_reviews, :only => [:index, :create, :edit, :update, :new, :destroy]
  end
end
