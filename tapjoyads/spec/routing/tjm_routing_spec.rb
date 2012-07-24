require 'spec_helper'

describe 'routes for tjm', :type => :routing do
  it 'should be routable' do
    get('games/translations/zh-cn-3333333.js').should route_to({:controller=>"games/homepage",
                                                                :action=>"translations",
                                                                :filename=> "zh-cn-3333333"})
  end
end
