ActionController::Routing::Routes.draw do |map|
  # Route old login page to new login page.
  map.connect 'Connect/Publish/Default.aspx', :controller => :user_sessions, :action => :new

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
  map.connect 'service1.asmx/PurchaseVGWithCurrency', :controller => 'points', :action => 'purchase_vg'
  map.connect 'Service1.asmx/PurchaseVGWithCurrency', :controller => 'points', :action => 'purchase_vg'

  # bunch of old rackspace routes
  map.connect 'service1.asmx/:action', :controller => 'rackspace'
  map.connect 'Service1.asmx/:action', :controller => 'rackspace'
  map.connect 'TapDefenseCurrencyService.asmx/:action', :controller => 'rackspace'
  map.connect 'TapPointsCurrencyService.asmx/:action', :controller => 'rackspace'
  map.connect 'RingtoneService.asmx/:action', :controller => 'rackspace'
  map.connect 'AppRedir.aspx/:action', :controller => 'rackspace'
  map.connect 'Redir.aspx/:action', :controller => 'rackspace'
  map.connect 'RateApp.aspx/:action', :controller => 'rackspace'
  map.connect 'Offers.aspx/:action', :controller => 'rackspace'

  # redirects from old vg controller
  map.connect 'purchase_vg', :controller => 'points', :action => 'purchase_vg'
  map.connect 'purchase_vg/spend', :controller => 'points', :action => 'spend'
end