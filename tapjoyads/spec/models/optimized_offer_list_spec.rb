require 'spec_helper'

describe OptimizedOfferList do

  before :each do
    @s3_key = '101.1.Android.US..android'
    @s3_offerwall_key = '101.0.Android.US..android'
    @cache_key = "s3.optimized_offer_list.101.tj_games.Android.US..android"
    @options = {
      :source=>"tj_games",
      :currency_id=>"",
      :country=>"US",
      :platform=>"Android",
      :algorithm=>"101",
      :device_type=>"android"
    }
  end

  # TODO I could not get this to work, it's hard to test because the code
  # gets a list of offer ids from s3, loads these offers, and puts them in memcache.
  # In the test environment the offers are not there, and any offer we create with factories or mock
  # will not have the same id as the file offers, so the find will fail.
  # I tried stubbing find, but it still didn't work.
  # describe ".cache_offer_list" do
  #   context "with an empty cache, getting a list of offers from s3" do
  #     it "caches a list of offers" do
  #       Offer.stubs(:find).returns(Factory(:app).primary_offer)
  #       fake_the_web
  #       OptimizedOfferList.cache_offer_list(@s3_key)
  #     end
  #   end
  # end

  # Testing the private methods that are important in this class

  describe ".options_for_s3_key" do
    context "when given an s3 key it returns a hash of options" do
      it "converts an s3 key into a hash correctly" do
        OptimizedOfferList.send(:options_for_s3_key, @s3_key).should == @options
      end
    end

    context "when given an s3 key for offerwall it returns correct options" do
      it "converts s3 key into a hash with offerwall as source" do
        OptimizedOfferList.send(:options_for_s3_key, @s3_offerwall_key)[:source].should == "offerwall"
      end
    end
  end

  describe ".cache_key_for_options" do
    context "when given a hash of option, it returns the correct key for the cache" do
      it "converts options into an s3 key correctly" do
        OptimizedOfferList.send(:cache_key_for_options, @options).should start_with @cache_key
      end
    end
  end

  describe ".s3_json_offer_data" do
    it "returns the data of a bucket in json with a list of offers and their rank score" do
      fake_the_web
      json = OptimizedOfferList.send(:s3_json_offer_data, @s3_key)
      json["key"].should == @s3_key
      json["enabled"].should == "true"
      offers = json["offers"]
      offers.should be_an Array
      offers.first.should be_a Hash
      offers.first.keys.should == ["rank_score", "offer_id"]
    end
  end

end
