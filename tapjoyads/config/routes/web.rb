ActionController::Routing::Routes.draw do |map|
  map.connect 'connect', :controller => :connect, :action => :index
  map.resources :offer_instructions, :only => [ :index ]
  map.resources :support_requests, :only => [ :new, :create ], :collection => { :incomplete_offers => :get }
  map.resources :tools_surveys, :only => [ :edit, :create ]
  map.resources :survey_results, :only => [ :new, :create ]
  map.resources :opt_outs, :only => :create
  map.resources :reengagement_rewards, :only => [ :index ]
  map.resources :videos, :only => [ :index ], :member => { :complete => :get }
  map.connect 'privacy', :controller => 'documents', :action => 'privacy'
  map.connect 'privacy.html', :controller => 'documents', :action => 'privacy'

  map.with_options :controller => :game_state do |m|
    m.load_game_state 'game_state/load', :action => :load
    m.save_game_state 'game_state/save', :action => :save
  end

  map.connect 'log_device_app/:action/:id', :controller => 'connect'
  map.connect 'confirm_email_validation', :controller => 'list_signup', :action => 'confirm_api'
end
