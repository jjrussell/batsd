ActionController::Routing::Routes.draw do |map|
  map.with_options({:path_prefix => MACHINE_TYPE == 'website' ? '' : 'games', :name_prefix => 'games_'}) do |m|
    m.root :controller => 'games/homepage', :action => :index
    m.tos 'tos', :controller => 'games/homepage', :action => :tos
    m.privacy 'privacy', :controller => 'games/homepage', :action => :privacy
    m.help 'help', :controller => 'games/homepage', :action => :help
    m.switch_device 'switch_device', :controller => 'games/homepage', :action => :switch_device
    m.send_device_link 'send_device_link', :controller => 'games/homepage', :action => :send_device_link
    m.earn 'earn/:currency_id', :controller => 'games/homepage', :action => :index, :load => 'earn'
    m.more_apps 'more_apps', :controller => 'games/homepage', :action => :index, :load => 'more_apps'

    m.more_games_editor_picks 'editor_picks', :controller => 'games/more_games', :action => :editor_picks
    m.more_games_recommended 'recommended', :controller => 'games/more_games', :action => :recommended

    m.resources :gamer_sessions, :controller => 'games/gamer_sessions', :only => [ :new, :create, :destroy, :index ]
    m.connect 'login', :controller => 'games/gamer_sessions', :action => :create, :conditions => {:method => :post}
    m.login 'login', :controller => 'games/gamer_sessions', :action => :new
    m.logout 'logout', :controller => 'games/gamer_sessions', :action => :destroy

    m.resource :gamer, :controller => 'games/gamers', :only => [ :create, :edit, :update, :destroy ],
      :member => { :password => :get, :prefs => :get, :update_password => :put, :accept_tos => :put, :confirm_delete => :get, :friends => :get } do |gamer|
      gamer.resource :device, :controller => 'games/gamers/devices', :only => [ :new, :create ], :member => { :finalize => :get }
      gamer.resource :gamer_profile, :controller => 'games/gamers/gamer_profiles', :only => [ :update ], :member => { :update_birthdate => :put, :update_prefs => :put }
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
    end

    m.resources :gamer_reviews, :controller => 'games/gamer_reviews', :only => [ :index, :new, :create, :edit, :update, :destroy]
  end
end
