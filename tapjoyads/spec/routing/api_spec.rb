require 'spec_helper'

describe 'routes for api' do
  it 'should be routable' do
    get('/').should route_to 'games/homepage#index'
    get('/click/app').should route_to 'click#app'
    get('/connect').should route_to 'connect#index'
    get('/Connect').should route_to 'connect#index'
    get('/log_device_app').should route_to 'connect#index'
    get('/set_publisher_user_id').should route_to 'set_publisher_user_id#index'
    get('/display_ad').should route_to 'display_ad#index', :format => "xml"
    get('/get_offers').should route_to 'get_offers#index'
    get('/get_offers/featured').should route_to 'get_offers#featured'
    get('/get_offers/webpage').should route_to 'get_offers#webpage'
    get('/get_vg_store_items/user_account').should route_to 'get_vg_store_items#user_account'
    get('/points/spend').should route_to 'points#spend'
    get('/videos').should route_to 'videos#index'
  end
end
