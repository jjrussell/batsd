require 'spec_helper'

describe 'routes for tjm', :type => :routing do
  it 'should be routable' do
    get('translations/test_filename-hashyhashhash.js')
  end
end
