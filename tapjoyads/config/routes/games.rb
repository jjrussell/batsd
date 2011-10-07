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
      gamer.resource :gamer_profile, :controller => 'games/gamers/gamer_profiles', :only => [ :edit, :update ]
    end
    m.register 'register', :controller => 'games/gamers', :action => :new
    
    m.resources :confirmations, :controller => 'games/confirmations', :only => [ :create ]
    m.confirm 'confirm', :controller => 'games/confirmations', :action => :create
    
    m.resources :password_resets, :controller => 'games/password_resets', :as => 'password-reset', :only => [ :new, :create, :edit, :update ]
    
    m.resources :support_requests, :controller => 'games/support_requests', :only => [ :new, :create ]
    
    m.resources :android, :controller => 'games/android', :action => :index
    
    m.social_invite_email_friends 'invite_email_friends', :controller => 'games/social', :action => :invite_email_friends
    m.social_send_email_invites 'send_email_invites', :controller => 'games/social', :action => :send_email_invites
    m.social_invite_facebook_friends 'invite_facebook_friends', :controller => 'games/social', :action => :invite_facebook_friends
    m.social_send_facebook_invites 'send_facebook_invites', :controller => 'games/social', :action => :send_facebook_invites
  end
end
