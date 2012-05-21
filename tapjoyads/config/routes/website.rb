Tapjoyad::Application.routes.draw do
  root :to => 'games/homepage#index'

  match 'assets/*filename' => 'sprocket#show', :as => :assets

  scope :module => :homepage do
    match 'site/privacy' => 'documents#privacy'
    match 'site/privacy.html' => 'documents#privacy'
    match 'site/privacy_mobile' => 'documents#privacy_mobile'
    match 'site/:action' => 'homepage#index'
    match 'index.html' => 'homepage#index_redirect'
    match 'site/advertisers/whitepaper' => 'homepage#whitepaper'
    match 'press' => 'press#index'
    match 'press/:id' => 'press#show'
    match 'careers' => 'careers#index'
    match 'careers/:id' => 'careers#show'
    match 'glu' => 'press#glu'
    match 'publishing' => 'homepage#publishers'
    match 'androidfund' => 'androidfund#index'
    match 'AndroidFund' => 'androidfund#index'
    match 'androidfund/apply' => 'androidfund#apply'
    match 'privacy' => 'documents#privacy'
    match 'privacy.html' => 'documents#privacy'
    resources :opt_outs, :only => :create
  end

  games_scope = MACHINE_TYPE == 'website' ? '' : 'games'
  namespace :games, :path => games_scope  do
    root :to => 'homepage#index'
    match '/' => 'homepage#index'
    match 'tos' => 'homepage#tos', :as => :tos
    match 'privacy' => 'homepage#privacy', :as => :privacy
    match 'help' => 'homepage#help', :as => :help
    match 'switch_device' => 'homepage#switch_device', :as => :switch_device
    match 'send_device_link' => 'homepage#send_device_link', :as => :send_device_link
    match 'earn/:eid' => 'homepage#earn', :as => :earn
    match 'more_apps' => 'homepage#index', :as => :more_apps
    match 'get_app' => 'homepage#get_app', :as => :get_app
    match 'record_click' => 'homepage#record_click'
    match 'editor_picks' => 'more_games#editor_picks', :as => :more_games_editor_picks
    match 'recommended' => 'more_games#recommended', :as => :more_games_recommended
    match 'translations/:filename.js' => 'homepage#translations', :as => :translations
    resources :my_apps, :only => [:show, :index]
    resources :gamer_sessions, :only => [:new, :create, :destroy, :index]
    get 'login' => 'gamer_sessions#new', :as => :login
    post 'login' => 'gamer_sessions#create'
    match 'logout' => 'gamer_sessions#destroy', :as => :logout
    match 'support' => 'support_requests#new', :type => 'contact_support'
    match 'bugs' => 'support_requests#new', :type => 'report_bug'
    match 'feedback' => 'support_requests#new', :type => 'feedback'
    match 'partners/:id' => 'partners#show', :as => :show
    resource :gamer, :only => [:create, :edit, :update, :destroy, :show, :new] do
      member do
        put :update_password
        put :accept_tos
        get :password
        get :confirm_delete
        get :prefs
        resource :device, :only => [:new, :create] do
          member do
            get :finalize
          end
        end

        resource :favorite_app, :controller => :favorite_app, :only => [:create, :destroy]
      end
    end

    resources :gamer_profiles, :only => [:show, :edit, :update] do
      member do
        put :update_prefs
        put :dissociate_account
        put :update_birthdate
      end
    end
    match 'register' => 'gamers#new', :as => :register
    resources :confirmations, :only => [:create]
    match 'confirm' => 'confirmations#create', :as => :confirm
    resources :password_resets, :only => [:new, :create, :edit, :update]
    match 'password-reset' => 'password_resets#new', :as => :password_reset
    resources :support_requests, :only => [:new, :create] do
      collection do
        get :unresolved_clicks
      end
    end
    resources :android
    resources :survey_results, :only => [:new, :create]
    resources :app_reviews , :only => [:index, :create, :edit, :update, :new, :destroy] do
      resource :fave, :controller => 'app_reviews/fave_moderation', :only => [:create, :destroy]
      resource :flag, :controller => 'app_reviews/flag_moderation', :only => [:create, :destroy]
    end
    # TODO: Fix this legacy namespacing weirdness
    namespace :social, :path => '' do
      match 'social' => 'social#index', :as => :root
      match 'invite_email_friends' => 'social#invite_email_friends', :as => :invite_email_friends
      match 'social/connect_facebook_account' => 'social#connect_facebook_account', :as => :connect_facebook_account
      match 'send_email_invites' => 'social#send_email_invites', :as => :send_email_invites
      match 'invite_twitter_friends' => 'social#invite_twitter_friends', :as => :invite_twitter_friends
      match 'send_twitter_invites' => 'social#send_twitter_invites', :as => :send_twitter_invites
      match 'get_twitter_friends' => 'social#get_twitter_friends', :as => :get_twitter_friends
      match 'social/invites' => 'social#invites', :as => :invites
      match 'social/friends' => 'social#friends', :as => :friends
      scope :twitter do
        match 'start_oauth' => 'twitter#start_oauth', :as => :twitter_start_oauth
        match 'finish_oauth' => 'twitter#finish_oauth', :as => :twitter_finish_oauth
      end
    end
  end
end
