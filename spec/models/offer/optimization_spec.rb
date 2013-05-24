require 'spec_helper'

describe Offer::Optimization do
  describe "#override_rank_score" do
    before :each do
      @offer_hash = {'rank_score' => 200.7}
      generic_offer = FactoryGirl.create(:generic_offer)
      @offer = generic_offer.primary_offer
      @offer.rank_score = 100
      @offer.save
    end

    it "should use rank_score from offer_hash" do
      @offer.optimization_override(@offer_hash, false)
      @offer.rank_score.should == 200.7
    end

    context "rank_boost overriding rank score" do
      before :each do
        @rank_boost = RankBoost.create(:offer_id => @offer.id,
                                    :start_time => Time.now - 1.hour, :end_time => Time.now + 1.hour,
                                    :amount => 0)
        @offer.publisher_app_whitelist = ""
        @offer.calculate_rank_boost!
        @offer.save
      end

      it "should not override rank_score with rank_boost if publisher_app_whitelist is blank" do
        @offer.optimization_override(@offer_hash, false)
        @offer.rank_score.should == 200.7
      end

      it "should not override rank_score when rank_boost == 0 even if publisher_app_whitelist is present" do
        @offer.publisher_app_whitelist = "0001"
        @offer.save

        @offer.optimization_override(@offer_hash, false)
        @offer.rank_score.should == 200.7
      end

      it "should override rank_score with rank_boost with addition of rank_boost and optimized rank_score if publisher_app_whitelist is present" do
        @rank_boost.amount = 500
        @rank_boost.save

        @offer.calculate_rank_boost!
        @offer.publisher_app_whitelist = "0001"
        @offer.save

        @offer.optimization_override(@offer_hash, false)
        @offer.rank_score.should == 500 + 200.7
      end

      it "should not override rank_score with rank_boost with addition of rank_boost and optimized rank_score if publisher_app_whitelist is present but rank boost > 1000" do
        @rank_boost.amount = 1500
        @rank_boost.save

        @offer.calculate_rank_boost!
        @offer.publisher_app_whitelist = "0001"
        @offer.save

        @offer.optimization_override(@offer_hash, false)
        @offer.rank_score.should == 200.7
      end

      it "should override rank_score with rank_boost with addition of rank_boost and optimized rank_score if rank_boost < 0", :negative_rank_boost do
        @rank_boost.amount = -800
        @rank_boost.save

        @offer.calculate_rank_boost!
        @offer.save

        @offer.optimization_override(@offer_hash, false)
        @offer.rank_score.should == -800 + 200.7
      end

    end
  end
end
