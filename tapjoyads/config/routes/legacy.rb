Tapjoyad::Application.routes.draw do
  match 'service1.asmx/Connect' => 'connect#index'
  match 'Service1.asmx/Connect' => 'connect#index'
  match 'service1.asmx/AdShown' => 'adshown#index'
  match 'Service1.asmx/AdShown' => 'adshown#index'
  match 'service1.asmx/SubmitTapjoyAdClick' => 'submit_click#ad'
  match 'Service1.asmx/SubmitTapjoyAdClick' => 'submit_click#ad'
  match 'service1.asmx/SubmitAppStoreClick' => 'submit_click#store'
  match 'Service1.asmx/SubmitAppStoreClick' => 'submit_click#store'
  match 'service1.asmx/GetAppIcon' => 'get_app_image#icon'
  match 'Service1.asmx/GetAppIcon' => 'get_app_image#icon'
  match 'service1.asmx/GetOffersForPublisherCurrencyByType' => 'get_offers#index'
  match 'Service1.asmx/GetOffersForPublisherCurrencyByType' => 'get_offers#index'
  match 'service1.asmx/GetTapjoyAd' => 'getad#index'
  match 'Service1.asmx/GetTapjoyAd' => 'getad#index'
  match 'service1.asmx/GetAdOrder' => 'get_ad_order#index'
  match 'Service1.asmx/GetAdOrder' => 'get_ad_order#index'
  match 'service1.asmx/SubmitOfferClick' => 'submit_click#offer'
  match 'Service1.asmx/SubmitOfferClick' => 'submit_click#offer'
  match 'service1.asmx/GetUserOfferStatus' => 'offer_status#index'
  match 'Service1.asmx/GetUserOfferStatus' => 'offer_status#index'
  match 'service1.asmx/GetAllVGStoreItems' => 'get_vg_store_items#all'
  match 'Service1.asmx/GetAllVGStoreItems' => 'get_vg_store_items#all'
  match 'service1.asmx/GetPurchasedVGStoreItems' => 'get_vg_store_items#purchased'
  match 'Service1.asmx/GetPurchasedVGStoreItems' => 'get_vg_store_items#purchased'
  match 'service1.asmx/GetUserAccountObject' => 'get_vg_store_items#user_account'
  match 'Service1.asmx/GetUserAccountObject' => 'get_vg_store_items#user_account'
  match 'service1.asmx/PurchaseVGWithCurrency' => 'points#purchase_vg'
  match 'Service1.asmx/PurchaseVGWithCurrency' => 'points#purchase_vg'
  match 'service1.asmx/:action' => 'rackspace#index'
  match 'Service1.asmx/:action' => 'rackspace#index'
  match 'TapDefenseCurrencyService.asmx/:action' => 'rackspace#index'
  match 'TapPointsCurrencyService.asmx/:action' => 'rackspace#index'
  match 'RingtoneService.asmx/:action' => 'rackspace#index'
  match 'AppRedir.aspx/:action' => 'rackspace#index'
  match 'Redir.aspx/:action' => 'rackspace#index'
  match 'RateApp.aspx/:action' => 'rackspace#index'
  match 'Offers.aspx/:action' => 'rackspace#index'
  match 'purchase_vg' => 'points#purchase_vg'
  match 'purchase_vg/spend' => 'points#spend'
end
