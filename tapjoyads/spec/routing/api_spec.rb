require 'spec_helper'

describe 'routes for api' do
  it 'should be routable' do
    get('/').should route_to 'homepage#start'
    get('/click/app').should route_to 'click#app'
    get('/get_offers').should route_to 'get_offers#index'
    get('/get_vg_store_items/user_account').should route_to 'get_vg_store_items#user_account'
  end
end
