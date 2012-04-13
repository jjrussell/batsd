require 'spec/spec_helper'

describe Job::MasterCacheOffersController do
  before :each do
    @controller.expects(:authenticate).at_least_once.returns(true)
  end

  describe '#index' do
    it "runs without errors" do
      get(:index)
    end
  end
end
