ActionController::Routing::Routes.draw do |map|
  map.with_options({:path_prefix => MACHINE_TYPE == 'website' ? '' : 'games', :name_prefix => 'games_'}) do |m|
    m.root :controller => 'games/homepage', :action => :index
    m.tos 'tos', :controller => 'games/homepage', :action => :tos
    m.privacy 'privacy', :controller => 'games/homepage', :action => :privacy
    m.help 'help', :controller => 'games/homepage', :action => :help
    m.switch_device 'switch_device', :controller => 'games/homepage', :action => :switch_device
    m.send_device_link 'send_device_link', :controller => 'games/homepage', :action => :send_device_link
    m.earn 'earn/:id', :controller => 'games/homepage', :action => :earn, :load => 'earn'
    m.more_apps 'more_apps', :controller => 'games/homepage', :action => :index, :load => 'more_apps'
    m.get_app 'get_app', :controller => 'games/homepage', :action => :get_app, :load => 'get_app'

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

    m.resources :gamer, :controller => 'games/gamers', :only => [ :create, :edit, :update, :destroy, :show ],
      :member => { :password => :get, :prefs => :get, :social => :get, :update_password => :put, :accept_tos => :put, :confirm_delete => :get, :connect_facebook_account => :get } do |gamer|
      gamer.resource :device, :controller => 'games/gamers/devices', :only => [ :new, :create ], :member => { :finalize => :get }
      gamer.resource :gamer_profile, :controller => 'games/gamers/gamer_profiles', :only => [ :update ], :member => { :update_birthdate => :put, :update_prefs => :put, :dissociate_account => :put }
    end

    m.register 'register', :controller => 'games/gamers', :action => :new

    m.resources :confirmations, :controller => 'games/confirmations', :only => [ :create ]
    m.confirm 'confirm', :controller => 'games/confirmations', :action => :create

    m.resources :password_resets, :controller => 'games/password_resets', :as => 'password-reset', :only => [ :new, :create, :edit, :update ]
    m.password_reset 'password-reset', :controller => 'games/password_resets', :action => :new

    m.resources :support_requests, :controller => 'games/support_requests', :only => [ :new, :create ]

    m.resources :android, :controller => 'games/android', :action => :index

    m.resources :social, :only => [:index], :controller => 'games/social'
    map.with_options :controller => 'games/social', :name_prefix => 'games_social_' do |social|
      social.invite_email_friends 'invite_email_friends', :action => :invite_email_friends
      social.send_email_invites 'send_email_invites', :action => :send_email_invites
    end

    map.resources :survey_results, :only => [ :new, :create ]
    m.resources :app_reviews, :controller => 'games/app_reviews', :only => [ :index, :create, :edit, :update, :new, :destroy]
  end
end
