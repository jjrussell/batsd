ActionController::Routing::Routes.draw do |map|
  # Additional webserver routes
  map.resources :offer_instructions, :only => [ :index ]
  map.resources :support_requests, :only => [ :new, :create ]
  map.resources :surveys, :only => [ :edit, :create ]
  map.resources :opt_outs, :only => :create
  map.connect 'privacy', :controller => 'homepage', :action => 'privacy'
  map.connect 'privacy.html', :controller => 'homepage', :action => 'privacy'
  
  map.with_options :controller => :game_state do |m|
    m.load_game_state 'game_state/load', :action => :load
    m.save_game_state 'game_state/save', :action => :save
  end
  
  map.connect 'log_device_app/:action/:id', :controller => 'connect'
  map.connect 'confirm_email_validation', :controller => 'list_signup', :action => 'confirm_api'
end
