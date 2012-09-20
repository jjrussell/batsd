require 'spec_helper'

describe OfferCacher do
  before :each do
    Rails.cache.clear
    class Mc
      def self.cache_test_distributed_put(key, value, clone=false,time=1.day)
        Rails.cache.write(key, value)
      end

      def self.cache_test_distributed_get_and_put(key, clone=false,time=1.day)
        value = Rails.cache.fetch(key)
        self.distributed_put(key, value, clone, time) if value
        value
      end

      class << self
        alias_method :original_distributed_put, :distributed_put
        alias_method :original_distributed_get_and_put, :distributed_get_and_put

        alias_method :distributed_put, :cache_test_distributed_put
        alias_method :distributed_get_and_put, :cache_test_distributed_get_and_put
      end
    end

    @platform = "iOS"
    @device_type = "iphone"
    @offers = []
    @ranks = [1.0, 5.0, 3.0, 4.0, 2.0]
    @ranks.each do |rank|
      app = FactoryGirl.create(:app)
      offer = app.primary_offer
      offer.rank_score = rank
      offer.device_types = [@device_type].to_json
      offer.save!
      @offers << offer
    end
  end

  after :each do
    class Mc
      class << self
        alias_method :distributed_put, :original_distributed_put
        alias_method :distributed_get_and_put, :original_distributed_get_and_put
        remove_method :cache_test_distributed_put
        remove_method :cache_test_distributed_get_and_put
      end
    end
  end

  describe ".get_offers_prerejected" do
    it "caches sorted offers prerejected", :sorted do
      OfferCacher.cache_offers_prerejected(@offers, Offer::CLASSIC_OFFER_TYPE, false)
      offers = OfferCacher.get_offers_prerejected(Offer::CLASSIC_OFFER_TYPE, @platform, false, @device_type)
      offers.map {|o| o.rank_score}.should == @ranks.sort.reverse
    end
  end
end
