ActionController::Routing::Routes.draw do |map|
  map.root :controller => :homepage, :action => 'start'
  map.connect 'site/:action', :controller => 'homepage'
  map.connect 'index.html', :controller => 'homepage', :action => 'index'
  map.connect 'site/advertisers/whitepaper', :controller => 'homepage', :action => 'whitepaper'
  map.connect 'press', :controller => 'homepage/press', :action => 'index'
  map.connect 'press/:id', :controller => 'homepage/press', :action => 'show'
  map.connect 'careers', :controller => 'homepage/careers', :action => 'index'
  map.connect 'careers/:id', :controller => 'homepage/careers', :action => 'show'
  map.connect 'glu', :controller => 'homepage/press', :action => 'glu'
  map.connect 'publishing', :controller => 'homepage', :action => 'publishers'
  map.connect 'androidfund', :controller => 'androidfund'
  map.connect 'AndroidFund', :controller => 'androidfund'
  map.connect 'androidfund/apply', :controller => 'androidfund', :action => :apply
  map.connect 'privacy', :controller => 'homepage', :action => 'privacy'
  map.connect 'privacy.html', :controller => 'homepage', :action => 'privacy'
  map.resources :opt_outs, :only => :create
end
