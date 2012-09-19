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

  describe "#get_offers_prerejected" do
    it "caches sorted offers prerejected", :sorted do
      OfferCacher.cache_offers_prerejected(@offers, Offer::CLASSIC_OFFER_TYPE, false)
      offers = OfferCacher.get_offers_prerejected(Offer::CLASSIC_OFFER_TYPE, @platform, false, @device_type)
      offers.map {|o| o.rank_score}.should == @ranks.sort.reverse
    end

    it "caches sorted offers prerejected overriden by rank boost", :sorted, :rank_boost do
      overriden_offer = @offers[2]  # override offer with rank score of 3.0
      rank_boost = RankBoost.create(:offer_id => overriden_offer.id,
                                    :start_time => Time.now, :end_time => Time.now + 1.hour,
                                    :amount => 30)
      overriden_offer.publisher_app_whitelist = "0001"
      overriden_offer.calculate_rank_boost!
      overriden_offer.save

      OfferCacher.cache_offers_prerejected(@offers, Offer::CLASSIC_OFFER_TYPE, false)
      offers = OfferCacher.get_offers_prerejected(Offer::CLASSIC_OFFER_TYPE, @platform, false, @device_type)
      offers.map {|o| o.rank_score}.should == [33.0, 5.0, 4.0, 2.0, 1.0]
    end
  end
end
