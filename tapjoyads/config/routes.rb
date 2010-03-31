ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end
  
  # User controller is exposed as resource
  map.namespace :site do |site|
    site.resources :users, :only => [:show, :create], :new => {:login => :post}
    site.resources :apps, :only => [:show, :index]
    site.resources :appstats, :only => [:show, :index]
  end
  
  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"
  
  # Special paths:
  map.connect 'log_device_app/:action/:id', :controller => 'connect'
  map.connect 'confirm_email_validation', :controller => 'list_signup', :action => 'confirm_api'
  
  # Service1.asmx redirects. (Must include both lower-case and capital: service1.asmx and Service1.asmx).
  # These paths will be supported indefinitely - or as long as we support the legacy api.
  map.connect 'service1.asmx/Connect', :controller => 'connect'
  map.connect 'Service1.asmx/Connect', :controller => 'connect'
  map.connect 'service1.asmx/AdShown', :controller => 'adshown'
  map.connect 'Service1.asmx/AdShown', :controller => 'adshown'
  map.connect 'service1.asmx/SubmitTapjoyAdClick', :controller => 'submit_click', :action => 'ad'
  map.connect 'Service1.asmx/SubmitTapjoyAdClick', :controller => 'submit_click', :action => 'ad'
  map.connect 'service1.asmx/SubmitAppStoreClick', :controller => 'submit_click', :action => 'store'
  map.connect 'Service1.asmx/SubmitAppStoreClick', :controller => 'submit_click', :action => 'store'
  map.connect 'service1.asmx/GetAppIcon', :controller => 'get_app_image', :action => 'icon'
  map.connect 'Service1.asmx/GetAppIcon', :controller => 'get_app_image', :action => 'icon'
  map.connect 'service1.asmx/GetOffersForPublisherCurrencyByType', :controller => 'get_offers'
  map.connect 'Service1.asmx/GetOffersForPublisherCurrencyByType', :controller => 'get_offers'
  map.connect 'service1.asmx/GetTapjoyAd', :controller => 'getad'
  map.connect 'Service1.asmx/GetTapjoyAd', :controller => 'getad'
  map.connect 'service1.asmx/GetAdOrder', :controller => 'get_ad_order'
  map.connect 'Service1.asmx/GetAdOrder', :controller => 'get_ad_order'
  map.connect 'service1.asmx/SubmitOfferClick', :controller => 'submit_click', :action => 'offer'
  map.connect 'Service1.asmx/SubmitOfferClick', :controller => 'submit_click', :action => 'offer'
  map.connect 'service1.asmx/GetUserOfferStatus', :controller => 'offer_status'
  map.connect 'Service1.asmx/GetUserOfferStatus', :controller => 'offer_status'
  map.connect 'service1.asmx/GetAllVGStoreItems', :controller => 'get_vg_store_items', :action => 'all'
  map.connect 'Service1.asmx/GetAllVGStoreItems', :controller => 'get_vg_store_items', :action => 'all'
  map.connect 'service1.asmx/GetPurchasedVGStoreItems', :controller => 'get_vg_store_items', :action => 'purchased'
  map.connect 'Service1.asmx/GetPurchasedVGStoreItems', :controller => 'get_vg_store_items', :action => 'purchased'
  map.connect 'service1.asmx/GetUserAccountObject', :controller => 'get_vg_store_items', :action => 'user_account'
  map.connect 'Service1.asmx/GetUserAccountObject', :controller => 'get_vg_store_items', :action => 'user_account'
  map.connect 'service1.asmx/PurchaseVGWithCurrency', :controller => 'purchase_vg'
  map.connect 'Service1.asmx/PurchaseVGWithCurrency', :controller => 'purchase_vg'
  
  map.connect 'service1.asmx/:action', :controller => 'service1'
  map.connect 'Service1.asmx/:action', :controller => 'service1'
  
  # OFFERS TODO
  # Route GetOffersForPublsherCurrencyByType to get_offers
  # Route SubmitOfferClick to submit_click/offer
  
  map.connect 'ReceiveOffersService.asmx/ReceiveOffer', :controller => 'receive_offer', :action => 'receive_offer'
  map.connect 'ReceiveOffersService.asmx/ReceiveOfferCS', :controller => 'receive_offer', :action => 'receive_offer_cs'
  
  # Generic windows redirectors. These will be transitions over to ruby controllers as
  # functionality is moved off of windows.
  map.connect 'TapDefenseCurrencyService.asmx/:action', :controller => 'win_redirector'
  map.connect 'TapPointsCurrencyService.asmx/:action', :controller => 'win_redirector'
  map.connect 'RingtoneService.asmx/:action', :controller => 'win_redirector'
  map.connect 'AppRedir.aspx/:action', :controller => 'win_redirector'
  map.connect 'Redir.aspx/:action', :controller => 'win_redirector'
  map.connect 'RateApp.aspx/:action', :controller => 'win_redirector'

  map.connect 'Offers.aspx/:action', :controller => 'win_redirector'
  
  # Authenticated windows redirectors. These too will be removed/moved to standard 
  # ruby controllers in time.
  map.connect 'CronService.asmx/:action', :controller => 'authenticated_win_redirector'
  
  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller.:format'
    
end
