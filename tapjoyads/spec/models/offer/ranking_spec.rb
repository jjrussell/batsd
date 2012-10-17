require 'spec_helper'

describe Offer::Ranking do
  describe "#calculate_ranking_fields" do
    before :each do
      generic_offer = FactoryGirl.create(:generic_offer)
      @offer = generic_offer.primary_offer
      @currency_group = FactoryGirl.create(:currency_group, :random => 0)
    end

    it "should make use of rank boost to calculate rank scores" do
      @rank_boost = RankBoost.create(:offer_id => @offer.id,
                                  :start_time => Time.now - 1.hour,
                                  :end_time => Time.now + 1.hour,
                                  :amount => 300)
      @offer.calculate_rank_boost!
      @offer.save
      @offer.rank_score.should == @rank_boost.amount
    end
  end

  describe "#override_rank_score" do
    before :each do
      generic_offer = FactoryGirl.create(:generic_offer)
      @offer = generic_offer.primary_offer
      @offer.save
      @rank_boost = RankBoost.create(:offer_id => @offer.id,
                                  :start_time => Time.now - 1.hour, :end_time => Time.now + 1.hour,
                                  :amount => 0)
      @offer.rank_score = 100.8
      @offer.calculate_rank_boost!
      @offer.save
    end

    it "should not override rank score with rank boost when rank_boost == 0" do
      @offer.override_rank_score
      @offer.rank_score.should == 100.8
    end

    it "should not override rank score with rank boost when publisher_app_whitelist is blank" do
      @rank_boost.amount = 200
      @rank_boost.save
      @offer.calculate_rank_boost!

      @offer.publisher_app_whitelist = ""
      @offer.override_rank_score
      @offer.save

      @offer.rank_score.should == 100.8
    end

    it "should override rank score with rank boost + rank_score when publisher_app_whitelist is not blank" do
      @rank_boost.amount = 200
      @rank_boost.save
      @offer.calculate_rank_boost!

      @offer.publisher_app_whitelist = "0001"
      @offer.override_rank_score
      @offer.save

      @offer.rank_score.should == 200
    end

    it "should not override rank score with rank boost when publisher_app_whitelist is not blank but rank boost > 1000" do
      @rank_boost.amount = 1500
      @rank_boost.save
      @offer.calculate_rank_boost!

      @offer.publisher_app_whitelist = "0001"
      @offer.override_rank_score
      @offer.save

      @offer.rank_score.should == 100.8
    end

    it "should override rank score with rank boost + rank_score when rank boost < 0" do
      @rank_boost.amount = -200
      @rank_boost.save
      @offer.calculate_rank_boost!

      @offer.override_rank_score
      @offer.save

      @offer.rank_score.should == -200
    end

    it "should override rank score with rank boost if rank_score is not already set" do
      @offer.rank_score = nil
      @offer.save

      @rank_boost.amount = 200
      @rank_boost.save
      @offer.calculate_rank_boost!

      @offer.publisher_app_whitelist = "0001"
      @offer.override_rank_score
      @offer.save

      @offer.rank_score.should == 200
    end
  end
end
