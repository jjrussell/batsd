require 'spec_helper'

describe 'routes for api' do
  it 'should be routable' do
    get('/').should route_to 'homepage#start'
    get('/click/app').should route_to 'click#app'
    get('/connect').should route_to 'connect#index'
    get('/display_ad').should route_to 'display_ad#index'
    get('/get_offers').should route_to 'get_offers#index'
    get('/get_offers/featured').should route_to 'get_offers#featured'
    get('/get_offers/webpage').should route_to 'get_offers#webpage'
    get('/get_vg_store_items/user_account').should route_to 'get_vg_store_items#user_account'
    get('/points/spend').should route_to 'points#spend'
    get('/videos').should route_to 'videos#index'
  end
end
