require 'spec_helper'

describe OfferList do
  before :each do
    fake_the_web
    RailsCache.flush
  end

  context 'with a bad device' do
    before :each do
      @banned_device = Factory(:device, :banned => true)
      @opted_out_device = Factory(:device, :opted_out => true)
      RailsCache.expects(:get_and_put).never
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
      @currency = Factory(:currency)
      @currency.expects(:tapjoy_enabled?).returns(false)
      RailsCache.expects(:get_and_put).never
    end

    it 'returns no offers' do
      list = OfferList.new(:currency => @currency)
      list.offers.should == []
    end
  end

  context 'with an app' do
    before :each do
      @app = Factory(:app, :platform => 'windows')
    end

    it 'overwrites the platform_name parameter with the app platform name' do
      OfferCacher.expects(:get_unsorted_offers_prerejected).with(anything, 'Windows', anything, anything)
      OfferList.new(:publisher_app => @app, :platform_name => 'ValueFromParameter', :type => Offer::DISPLAY_OFFER_TYPE)
    end

    context 'called with a null device_type' do
      before :each do
        Device.stubs(:normalize_device_type).with(nil).returns(nil)
      end

      it 'uses the app platform for windows or android' do
        ['android', 'windows'].each do |platform|
          @app.platform = platform
          OfferCacher.expects(:get_unsorted_offers_prerejected).with(anything, anything, anything, platform)
          OfferList.new(:publisher_app => @app, :device_type => nil, :type => Offer::DISPLAY_OFFER_TYPE)
        end
      end

      it 'uses itouch for any other platform' do
        other_platforms = App::PLATFORMS.keys - ['android', 'windows']
        OfferCacher.expects(:get_unsorted_offers_prerejected).with(anything, anything, anything, 'itouch').times(other_platforms.count)
        other_platforms.each do |platform|
          @app.platform = platform
          OfferList.new(:publisher_app => @app, :device_type => nil, :type => Offer::DISPLAY_OFFER_TYPE)
        end
      end
    end

    context 'called with a valid device type' do
      before :each do
        Device.expects(:normalize_device_type).with('Android 2.3.4').returns('android')
      end

      it 'uses the parameter value, rather than the app platform' do
        OfferCacher.expects(:get_unsorted_offers_prerejected).with(anything, anything, anything, 'android')
        OfferList.new(:publisher_app => @app, :device_type => 'Android 2.3.4', :type => Offer::DISPLAY_OFFER_TYPE)
      end
    end
  end

  context 'with currency set to hide_rewarded_app_installs' do
    before :each do
      @currency = Factory(:currency)
      @currency.stubs(:hide_rewarded_app_installs_for_version?).returns(true)
    end

    it 'replaces each rewarded offer type with its non-rewarded equivalent' do
      {
        Offer::FEATURED_OFFER_TYPE => Offer::NON_REWARDED_FEATURED_OFFER_TYPE,
        Offer::FEATURED_BACKFILLED_OFFER_TYPE => Offer::NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE,
        Offer::DISPLAY_OFFER_TYPE => Offer::NON_REWARDED_DISPLAY_OFFER_TYPE
      }.each do |type,nonrew_equiv|
        OfferCacher.expects(:get_unsorted_offers_prerejected).with(nonrew_equiv, anything, anything, anything).returns([])
        OfferList.new(:currency => @currency, :type => type)
      end
    end
  end
end
