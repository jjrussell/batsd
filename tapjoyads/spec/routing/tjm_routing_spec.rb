require 'spec_helper'

describe 'routes for tjm' do
  it 'should be routable' do
    get('translations/test_filename-hashyhashhash.js')
  end
end
