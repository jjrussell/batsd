ActionController::Routing::Routes.draw do |map|
  map.namespace :agency_api do |agency|
    agency.resources :apps, :only => [ :index, :show, :create, :update ]
    agency.resources :partners, :only => [ :index, :show, :create, :update ], :collection => { :link => :post }
    agency.resources :currencies, :only => [ :index, :show, :create, :update ]
  end

  map.resources :reporting_data, :only => :index, :collection => { :udids => :get }

  map.connect 'adways_data',          :controller => :adways_data,          :action => :index
  map.connect 'brooklyn_packet_data', :controller => :brooklyn_packet_data, :action => :index
  map.connect 'ea_data',              :controller => :ea_data,              :action => :index
  map.connect 'fluent_data',          :controller => :fluent_data,          :action => :index
  map.connect 'glu_data',             :controller => :glu_data,             :action => :index
  map.connect 'gogii_data',           :controller => :gogii_data,           :action => :index
  map.connect 'loopt_data',           :controller => :loopt_data,           :action => :index
  map.connect 'ngmoco_data',          :controller => :ngmoco_data,          :action => :index
  map.connect 'pinger_data',          :controller => :pinger_data,          :action => :index
  map.connect 'pocketgems_data',      :controller => :pocketgems_data,      :action => :index
  map.connect 'sgn_data',             :controller => :sgn_data,             :action => :index
  map.connect 'zynga_data',           :controller => :zynga_data,           :action => :index
  map.connect 'tapulous_marketing',   :controller => :tapulous_marketing,   :action => :index
end
