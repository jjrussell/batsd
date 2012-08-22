require 'spec_helper'

describe Job::QueueCacheOptimizedOfferListController do
  before :each do
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)
    @cache_keys = ["key_a", "key_b"]
    OptimizedOfferList.stub(:s3_optimization_keys).and_return(@cache_keys)
    OptimizedOfferList.cache_all
  end

  it "enques a cache optimized offed list message for key_a" do
    Sqs.should_receive(:send_message).with(QueueNames::CACHE_OPTIMIZED_OFFER_LIST, "key_a").once
  end

  it "enques a cache optimized offed list message for key_b" do
    Sqs.should_receive(:send_message).with(QueueNames::CACHE_OPTIMIZED_OFFER_LIST, "key_b").once
  end

  it "should put keys onto cache" do
    get(:index)
  end
end
