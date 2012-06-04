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

  describe '#get_offers' do
    before :each do
      @offers = []
      10.times { @offers << Factory(:video_offer).primary_offer }
      RailsCache.stubs(:get_and_put).returns(RailsCacheValue.new(@offers))
      @currency = Factory(:currency)
      @app = @currency.app
      @base_params = {:device => Factory(:device), :publisher_app => @app, :currency => @currency, :video_offer_ids => @offers.map { |o| o.id }}
    end

    context 'with a bad device' do
      before :each do
        @banned_device = Factory(:device, :banned => true)
        @opted_out_device = Factory(:device, :opted_out => true)
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

      context 'with a deeplink offer' do
        before :each do
          @deeplink = @currency.deeplink_offer
          @deeplink.partner.balance = 100
          Offer.stubs(:find_in_cache).with(@deeplink.primary_offer.id).returns(@deeplink.primary_offer)
        end

        it 'returns the deeplink offer in the offerwall' do
          list = OfferList.new({:source => 'offerwall'}.merge(@base_params))
          offers, remaining = list.get_offers(0, 5)
          offers.should == @offers[0..2] + [@deeplink.primary_offer, @offers[3]]
        end

        it 'correctly inserts deeplink offers in small lists' do
          RailsCache.stubs(:get_and_put).returns(RailsCacheValue.new([]))
          list = OfferList.new({:source => 'offerwall'}.merge(@base_params))
          offers, remaining = list.get_offers(0,5)
          offers.should == [@deeplink.primary_offer]
        end

        it 'skips the deeplink offer when not on the offerwall' do
          list = OfferList.new({:source => 'featured'}.merge(@base_params))
          offers, remaining = list.get_offers(0, 5)
          offers.should == @offers[0..4]
        end

        it 'skips the deeplink offer on android' do
          list = OfferList.new({:device_type => 'android'}.merge(@base_params))
          offers, remaining = list.get_offers(0, 5)
          offers.should == @offers[0..4]
        end
      end

      context 'with a rating offer' do
        before :each do
          @rating = Factory(:rating_offer)
          @app.enabled_rating_offer_id = @rating.id
          Offer.stubs(:find_in_cache).with(@rating.primary_offer.id).returns(@rating.primary_offer)
          @rating.primary_offer.stubs(:postcache_reject?).returns(false)
        end

        it 'should return the rating offer first, but there is a defect so it raises a NameError' do
          list = OfferList.new({:include_rating_offer => true}.merge(@base_params))

          #I think the intended logic is:
          #  offers.should == [@rating.primary_offer] + @offers[0..1]
          #but there's a defect; see offer_list.rb
          lambda {
            list.get_offers(0, 3)
          }.should raise_error(NameError)
        end
      end

      context 'with no special offers' do
        it 'returns the normal first page' do
          list = OfferList.new(@base_params)
          offers, remaining = list.get_offers(0, 3)
          offers.should == @offers[0..2]
        end
      end
    end

    context 'second page' do
      context 'with a deeplink and rating offer' do
        before :each do
          @deeplink = @currency.deeplink_offer
          Offer.stubs(:find_in_cache).with(@deeplink.primary_offer.id).returns(@deeplink.primary_offer)
          @rating = Factory(:rating_offer)

          @app.enabled_rating_offer_id = @rating.id
          Offer.stubs(:find_in_cache).with(@rating.primary_offer.id).returns(@rating.primary_offer)
          @rating.primary_offer.stubs(:postcache_reject?).returns(false)
        end

        it 'skips the special offers' do
          list = OfferList.new({:source => 'offerwall'}.merge(@base_params))
          offers, remaining = list.get_offers(5, 5)
          #first page should have been: rating, offers[0], offers[1], deeplink, offers[2]
          #so, second page should be: offers[3], offers[4], offers[5], offers[6], offers[7]
          #EXCEPT there is a defect that always skips rating offers (see above), so:
          #first page is: offers[0], offers[1], offers[2], deeplink, offers[3]
          #second page is: offers[4..8]
          offers.should == @offers[4..8]
        end
      end

      context 'with no special offers' do
        it 'returns the correct range of offers' do
          list = OfferList.new(@base_params)
          offers, remaining = list.get_offers(5, 5)
          offers.should == @offers[5..9]
        end
      end
    end
  end
end
