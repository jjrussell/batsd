require 'spec_helper'

describe 'routes for api' do
  it 'should be routable' do
    get('/').should route_to 'homepage#start'
  end
end
