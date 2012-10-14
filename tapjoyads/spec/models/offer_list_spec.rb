require 'spec_helper'

describe OfferList do
  before :each do
    RailsCache.flush
  end

  context 'with a bad device' do
    before :each do
      @banned_device = FactoryGirl.create(:device, :banned => true)
      @opted_out_device = FactoryGirl.create(:device, :opted_out => true)
      RailsCache.should_receive(:get_and_put).never
    end

    it 'returns no offers for a banned device' do
      list = OfferList.new(:device => @banned_device)
      list.offers.should == []
    end

    it 'returns no offers for an opted-out device' do
      list = OfferList.new(:device => @opted_out_device)
      list.offers.should == []
    end
  end

  context 'with a non-Tapjoy currency' do
    before :each do
      @currency = FactoryGirl.create(:currency)
      @currency.should_receive(:tapjoy_enabled?).and_return(false)
      RailsCache.should_receive(:get_and_put).never
    end

    it 'returns no offers' do
      list = OfferList.new(:currency => @currency)
      list.offers.should == []
    end
  end

  context 'with an app' do
    before :each do
      @app = FactoryGirl.create(:app, :platform => 'windows')
    end

    it 'overwrites the platform_name parameter with the app platform name' do
      OfferCacher.should_receive(:get_offers_prerejected).with(anything, 'Windows', anything, anything)
      OfferList.new(:publisher_app => @app, :platform_name => 'ValueFromParameter', :type => Offer::DISPLAY_OFFER_TYPE).offers
    end

    context 'called with a null device_type' do
      before :each do
        Device.stub(:normalize_device_type).with(nil).and_return(nil)
      end

      it 'uses the app platform for windows or android' do
        ['android', 'windows'].each do |platform|
          @app.platform = platform
          OfferCacher.should_receive(:get_offers_prerejected).with(anything, anything, anything, platform)
          OfferList.new(:publisher_app => @app, :device_type => nil, :type => Offer::DISPLAY_OFFER_TYPE).offers
        end
      end

      it 'uses itouch for any other platform' do
        other_platforms = App::PLATFORMS.keys - ['android', 'windows']
        OfferCacher.should_receive(:get_offers_prerejected).with(anything, anything, anything, 'itouch').exactly(other_platforms.count).times
        other_platforms.each do |platform|
          @app.platform = platform
          OfferList.new(:publisher_app => @app, :device_type => nil, :type => Offer::DISPLAY_OFFER_TYPE).offers
        end
      end
    end

    context 'called with a valid device type' do
      before :each do
        Device.should_receive(:normalize_device_type).with('Android 2.3.4').and_return('android')
      end

      it 'uses the parameter value, rather than the app platform' do
        OfferCacher.should_receive(:get_offers_prerejected).with(anything, anything, anything, 'android')
        OfferList.new(:publisher_app => @app, :device_type => 'Android 2.3.4', :type => Offer::DISPLAY_OFFER_TYPE).offers
      end
    end
  end

  context 'with currency set to hide_rewarded_app_installs' do
    before :each do
      @currency = FactoryGirl.create(:currency)
      @currency.stub(:hide_rewarded_app_installs_for_version?).and_return(true)
    end

    it 'replaces each rewarded offer type with its non-rewarded equivalent' do
      {
        Offer::FEATURED_OFFER_TYPE => Offer::NON_REWARDED_FEATURED_OFFER_TYPE,
        Offer::FEATURED_BACKFILLED_OFFER_TYPE => Offer::NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE,
        Offer::DISPLAY_OFFER_TYPE => Offer::NON_REWARDED_DISPLAY_OFFER_TYPE
      }.each do |type,nonrew_equiv|
        OfferCacher.should_receive(:get_offers_prerejected).with(nonrew_equiv, anything, anything, anything).and_return([])
        OfferList.new(:currency => @currency, :type => type).offers
      end
    end
  end

  describe '#get_offers' do
    before :each do
      @offers = []
      10.times { @offers << FactoryGirl.create(:video_offer).primary_offer }
      @offers.each { |x| x.partner.balance = 10; x.save }
      OfferCacher.stub(:get_offers_prerejected).and_return(@offers)
      @currency = FactoryGirl.create(:currency)
      @app = @currency.app
      @base_params = {:device => FactoryGirl.create(:device), :publisher_app => @app, :currency => @currency, :video_offer_ids => @offers.map { |o| o.id }}
    end

    context 'with a bad device' do
      before :each do
        @banned_device = FactoryGirl.create(:device, :banned => true)
        @opted_out_device = FactoryGirl.create(:device, :opted_out => true)
      end

      it 'returns no offers for a banned device' do
        list = OfferList.new(:device => @banned_device).get_offers(0, 5)
        list.should == [[], 0]
      end

      it 'returns no offers for an opted-out device' do
        list = OfferList.new(:device => @opted_out_device).get_offers(0, 5)
        list.should == [[], 0]
      end
    end

    context 'first page' do
      it 'returns the expected offers' do
        list = OfferList.new(@base_params)
        list.get_offers(0, 3).should include @offers[0..2]
      end
    end

    context 'second page' do
      it 'returns the expected offers' do
        list = OfferList.new(@base_params)
        list.get_offers(5, 5).should include @offers[5..9]
      end
    end
  end
end
