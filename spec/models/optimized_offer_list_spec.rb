require 'spec_helper'

describe OptimizedOfferList do

  before :each do
    @s3_key = '101.1.Android.US..android'
    @s3_offerwall_key = '101.0.Android.US..android'
    @cache_key = 's3.optimized_offer_list.101.tj_games.Android.US..android'
    @options = {
      :source => 'tj_games',
      :currency_id => '',
      :country => 'US',
      :platform => 'Android',
      :algorithm => '101',
      :device_type => 'android'
    }
  end

  # TODO I could not get this to work, it's hard to test because the code
  # gets a list of offer ids from s3, loads these offers, and puts them in memcache.
  # In the test environment the offers are not there, and any offer we create with factories or mock
  # will not have the same id as the file offers, so the find will fail.
  # I tried stubbing find, but it still didn't work.
  # describe '.cache_offer_list' do
  #   context 'with an empty cache, getting a list of offers from s3' do
  #     it 'caches a list of offers' do
  #       Offer.stubs(:find).returns(FactoryGirl.create(:app).primary_offer)
  #       fake_the_web
  #       OptimizedOfferList.cache_offer_list(@s3_key)
  #     end
  #   end
  # end

  # Testing the private methods that are important in this class

  describe '.delete_cached_offer_list' do
    context 'when given an existing cache key' do
      before :each do
        Mc.stub(:distributed_get).and_return(nil)
        Mc.stub(:distributed_get).with("#{@cache_key}.0").and_return('some offers')
        Mc.stub(:distributed_delete).and_return(nil)
      end

      it 'deletes the cache key' do
        Mc.should_receive(:distributed_delete).with("#{@cache_key}.0")
        OptimizedOfferList.delete_cached_offer_list(@cache_key)
      end
    end

    context 'when given a non-existant cache key' do
      before :each do
        Mc.stub(:distributed_get).and_return(nil)
        Mc.stub(:distributed_delete).and_return(nil)
      end

      it "doesn't delete the cache key" do
        Mc.should_not_receive(:distributed_delete)
        OptimizedOfferList.delete_cached_offer_list(@cache_key)
      end

    end
  end

  describe '.options_for_s3_key' do
    context 'when given an s3 key it returns a hash of options' do
      it 'converts an s3 key into a hash correctly' do
        OptimizedOfferList.send(:options_for_s3_key, @s3_key).should == @options
      end
    end

    context 'when given an s3 key for offerwall it returns correct options' do
      it 'converts s3 key into a hash with offerwall as source' do
        OptimizedOfferList.send(:options_for_s3_key, @s3_offerwall_key)[:source].should == 'offerwall'
      end
    end
  end

  describe '.cache_key_for_options' do
    context 'when given a hash of option, it returns the correct key for the cache' do
      it 'converts options into an s3 key correctly' do
        OptimizedOfferList.send(:cache_key_for_options, @options).should start_with @cache_key
      end
    end
  end

  describe '.s3_json_offer_data' do
    it 'returns the data of a bucket in json with a list of offers and their rank score' do
      json = OptimizedOfferList.send(:s3_json_offer_data, @s3_key).first
      json['key'].should == @s3_key
      json['enabled'].should == 'true'
      offers = json['offers']
      offers.should be_an Array
      offers.first.should be_a Hash
      offers.first.keys.should =~ ['rank_score', 'offer_id']
    end
  end

  describe '.cache_all' do
    before :each do
      @cache_keys = ['key_a', 'key_b']
      OptimizedOfferList.stub(:s3_optimization_keys).and_return(@cache_keys)
      OptimizedOfferList.stub(:cache_offer_list).and_return(true)
    end

    it 'should enque a cache optimized offed list message for key_a' do
      Sqs.should_receive(:send_message).with(QueueNames::CACHE_OPTIMIZED_OFFER_LIST, @cache_keys[0]).once
      OptimizedOfferList.cache_all
    end

    it 'should enque a cache optimized offed list message for key_b' do
      Sqs.should_receive(:send_message).with(QueueNames::CACHE_OPTIMIZED_OFFER_LIST, @cache_keys[1]).once
      OptimizedOfferList.cache_all
    end
  end

  describe '.cache_offer_list' do
    before :each do
      @key = 'test_key'
      OptimizedOfferList.stub(:cache_key_for_options).and_return(@key)
    end

    it 'should delete_cached_offer_list and return', :cache_offer_list do
      OptimizedOfferList.stub(:s3_json_offer_data).with(@key).and_return({'enabled' => 'false', 'offers' => ['offer_id' => 'test_id']})
      OptimizedOfferList.should_receive(:delete_cached_offer_list).with(@key)
      Offer.should_not_receive(:find)
      OptimizedOfferList.cache_offer_list(@key)
    end

    it 'should try to find an offer', :cache_offer_list do
      OptimizedOfferList.stub(:s3_json_offer_data).with(@key).and_return({'enabled' => 'true', 'offers' => ['offer_id' => 'test_id']})
      Offer.should_receive(:find)
      OptimizedOfferList.cache_offer_list(@key)
    end
  end

  describe '.get_offers_for_cache' do
    before :each do
      @offers_json = [ {'offer_id' => '1'} ]
      @offer = double('Offer')
      Offer.stub(:find).with('1').and_return(@offer)
    end

    context 'when offer is disabled' do
      it 'will not cache the offer' do
        @offer.stub(:disabled? => true)
        OptimizedOfferList.send(:get_offers_for_cache, @offers_json, '','').should be_empty
      end
    end

    context 'offer list device not for offer' do
      it 'will not cache the offer' do
        @offer.stub(:disabled? => false)
        @offer.stub(:device_platform_mismatch? => true)
        OptimizedOfferList.send(:get_offers_for_cache, @offers_json, 'android','').should be_empty
      end
    end

    context 'offer list platform not for offer' do
      it 'will not cache the offer' do
        @offer.stub(:disabled? => false)
        @offer.stub(:device_platform_mismatch? => false)
        @offer.stub(:app_platform_mismatch? => true)
        OptimizedOfferList.send(:get_offers_for_cache, @offers_json, 'android','Android').should be_empty
      end
    end

    context 'offer list matches the offer' do
      it 'will cache the offer' do
        @offer.stub(:disabled? => false)
        @offer.stub(:device_platform_mismatch? => false)
        @offer.stub(:app_platform_mismatch? => false)
        @offer.stub(:optimization_override).with(any_args()).and_return(@offer)
        @offer.stub(:for_caching).with(any_args()).and_return(@offer)
        Offer.stub(:find).with(any_args()).and_return(@offer)
        OptimizedOfferList.send(:get_offers_for_cache, @offers_json, 'android','Android').should == [@offer]
      end
    end
  end
end
