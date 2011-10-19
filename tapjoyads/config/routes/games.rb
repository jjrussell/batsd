ActionController::Routing::Routes.draw do |map|
  map.with_options({:path_prefix => MACHINE_TYPE == 'games' ? '' : 'games', :name_prefix => 'games_'}) do |m|
    m.root :controller => 'games/homepage', :action => :index
    m.tos 'tos', :controller => 'games/homepage', :action => :tos
    m.privacy 'privacy', :controller => 'games/homepage', :action => :privacy
    
    m.more_games_editor_picks 'editor_picks', :controller => 'games/more_games', :action => :editor_picks
    m.more_games_popular 'popular', :controller => 'games/more_games', :action => :popular
    
    m.resources :gamer_sessions, :controller => 'games/gamer_sessions', :only => [ :new, :create, :destroy ]
    m.login 'login', :controller => 'games/gamer_sessions', :action => :new
    m.logout 'logout', :controller => 'games/gamer_sessions', :action => :destroy
    
    m.resource :gamer, :controller => 'games/gamers', :only => [ :create, :edit, :update ], :member => { :password => :get, :update_password => :put } do |gamer|
      gamer.resource :device, :controller => 'games/gamers/devices', :only => [ :new, :create ], :member => { :finalize => :get }
      gamer.resource :gamer_profile, :controller => 'games/gamers/gamer_profiles', :only => [ :update ], :member => { :update_birthdate => :put }
    end
    m.register 'register', :controller => 'games/gamers', :action => :new
    
    m.resources :confirmations, :controller => 'games/confirmations', :only => [ :create ]
    m.confirm 'confirm', :controller => 'games/confirmations', :action => :create
    
    m.resources :password_resets, :controller => 'games/password_resets', :as => 'password-reset', :only => [ :new, :create, :edit, :update ]
    
    m.resources :support_requests, :controller => 'games/support_requests', :only => [ :new, :create ]
    
    m.resources :android, :controller => 'games/android', :action => :index
    
    map.with_options :controller => 'games/social', :name_prefix => 'games_social_' do |social|
      social.invite_email_friends 'invite_email_friends', :action => :invite_email_friends
      social.send_email_invites 'send_email_invites', :action => :send_email_invites
      social.invite_facebook_friends 'invite_facebook_friends', :action => :invite_facebook_friends
      social.send_facebook_invites 'send_facebook_invites', :action => :send_facebook_invites
      social.invite_twitter_friends 'invite_twitter_friends', :action => :invite_twitter_friends
      social.send_twitter_invites 'send_twitter_invites', :action => :send_twitter_invites
    end
  end
  
  map.games_social_twitter_auth 'auth/twitter/callback', :controller => 'games/social/twitter', :action => :authenticate
  map.games_social_twitter_auth_failure 'auth/failure', :controller => 'games/social/twitter', :action => :failure
end
