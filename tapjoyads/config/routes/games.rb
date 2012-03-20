ActionController::Routing::Routes.draw do |map|
  map.assets "assets/*filename", :controller => "sprocket", :action => :show
  map.with_options({:path_prefix => MACHINE_TYPE == 'website' ? '' : 'games', :name_prefix => 'games_'}) do |m|


    m.root :controller => 'games/homepage', :action => :index
    m.tos 'tos', :controller => 'games/homepage', :action => :tos
    m.privacy 'privacy', :controller => 'games/homepage', :action => :privacy
    m.help 'help', :controller => 'games/homepage', :action => :help
    m.switch_device 'switch_device', :controller => 'games/homepage', :action => :switch_device
    m.send_device_link 'send_device_link', :controller => 'games/homepage', :action => :send_device_link
    m.earn 'earn/:id', :controller => 'games/homepage', :action => :earn
    m.more_apps 'more_apps', :controller => 'games/homepage', :action => :index
    m.get_app 'get_app', :controller => 'games/homepage', :action => :get_app

    m.more_games_editor_picks 'editor_picks', :controller => 'games/more_games', :action => :editor_picks
    m.more_games_recommended 'recommended', :controller => 'games/more_games', :action => :recommended

    m.translations 'translations', :controller => 'games/homepage', :action => :translations
    m.resources :my_apps, :controller => 'games/my_apps', :only => [ :show, :index ]

    m.resources :gamer_sessions, :controller => 'games/gamer_sessions', :only => [ :new, :create, :destroy, :index ]
    m.connect 'login', :controller => 'games/gamer_sessions', :action => :create, :conditions => {:method => :post}
    m.login 'login', :controller => 'games/gamer_sessions', :action => :new
    m.logout 'logout', :controller => 'games/gamer_sessions', :action => :destroy
    map.connect 'support',
      :controller => 'games/support_requests', :action => :new, :type => 'contact_support'
    map.connect 'bugs',
      :controller => 'games/support_requests', :action => :new, :type => 'report_bug'
    map.connect 'feedback',
      :controller => 'games/support_requests', :action => :new, :type => 'feedback'

    m.resource :gamer, :controller => 'games/gamers', :only => [ :create, :edit, :update, :destroy, :show, :new ],
      :member => { :password => :get, :prefs => :get, :update_password => :put, :accept_tos => :put, :confirm_delete => :get } do |gamer|
      gamer.resource :device, :controller => 'games/gamers/devices', :only => [ :new, :create ], :member => { :finalize => :get }
      gamer.resource :favorite_app, :controller => 'games/gamers/favorite_app', :only => [ :create, :destroy ]
      gamer.resource :gamer_profile, :controller => 'games/gamers/gamer_profiles', :only => [ :update ], :member => { :update_birthdate => :put, :update_prefs => :put, :dissociate_account => :put }
    end

    m.resources :gamer_profile, :controller => 'games/gamers/gamer_profiles', :only => [ :show, :edit, :update ]

    m.register 'register', :controller => 'games/gamers', :action => :new

    m.resources :confirmations, :controller => 'games/confirmations', :only => [ :create ]
    m.confirm 'confirm', :controller => 'games/confirmations', :action => :create

    m.resources :password_resets, :controller => 'games/password_resets', :as => 'password-reset', :only => [ :new, :create, :edit, :update ]
    m.password_reset 'password-reset', :controller => 'games/password_resets', :action => :new

    m.resources :support_requests, :controller => 'games/support_requests', :only => [ :new, :create ]

    m.resources :android, :controller => 'games/android', :action => :index

    m.resources :social, :only => [:index], :controller => 'games/social'
    m.with_options :controller => 'games/social', :name_prefix => 'games_social_' do |social|
      social.invite_email_friends 'invite_email_friends', :action => :invite_email_friends
      social.connect_facebook_account 'social/connect_facebook_account', :action => :connect_facebook_account
      social.send_email_invites 'send_email_invites', :action => :send_email_invites
      social.invite_twitter_friends 'invite_twitter_friends', :action => :invite_twitter_friends
      social.send_twitter_invites 'send_twitter_invites', :action => :send_twitter_invites
      social.get_twitter_friends 'get_twitter_friends', :action => :get_twitter_friends
      social.invites 'social/invites', :action => :invites
      social.friends 'social/friends', :action => :friends
    end

    map.with_options :controller => 'games/social/twitter', :name_prefix => 'games_social_twitter_' do |twitter|
      twitter.start_oauth 'twitter/start_oauth', :action => :start_oauth
      twitter.finish_oauth 'twitter/finish_oauth', :action => :finish_oauth
    end

    map.resources :survey_results, :only => [ :new, :create ]
    m.resources :app_reviews, :controller => 'games/app_reviews', :only => [ :index, :create, :edit, :update, :new, :destroy]
  end
end
