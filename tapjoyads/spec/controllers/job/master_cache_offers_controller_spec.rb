require 'spec/spec_helper'

describe Job::MasterCacheOffersController do
  before :each do
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)
  end

  describe '#index' do
    it "runs without errors" do
      get(:index)
    end
  end
end
