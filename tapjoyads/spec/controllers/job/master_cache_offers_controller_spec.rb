require 'spec/spec_helper'

describe Job::MasterCacheOffersController do
  before :each do
    @controller.expects(:authenticate).at_least_once.returns(true)
  end

  describe '#index' do
    it 'saves Offers to memcache' do
      get(:index)
    end
  end
end
