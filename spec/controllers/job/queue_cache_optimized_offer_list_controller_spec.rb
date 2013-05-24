require 'spec_helper'

describe Job::QueueCacheOptimizedOfferListController do
  before :each do
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)
    OptimizedOfferList.stub(:cache_offer_list).and_return(true)
  end

  it "should cache offer list with one key" do
    key = "key_x"
    OptimizedOfferList.should_receive(:cache_offer_list).with(key).once
    get(:run_job, :message => key)
  end
end
