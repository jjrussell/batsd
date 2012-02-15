require 'spec/spec_helper'

describe GetOffersController do
  integrate_views

  before :each do
    fake_the_web
  end

  describe "index" do
    before :each do
      @currency = Factory(:currency)
      @offer = Factory(:app).primary_offer
      @offer2 = Factory(:app).primary_offer
      @offer2.countries = ["GB"].to_json
      @offer2.save
      @offer3 = Factory(:app).primary_offer
      @offer3.countries = ["US"].to_json
      @offer3.save
      @offer4 = Factory(:app).primary_offer
      @offer4.countries = ["CN"].to_json
      @offer4.save

      offers = [ @offer, @offer2, @offer3, @offer4 ]
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns(offers)
      RailsCache.stubs(:get).returns(nil)
      controller.stubs(:get_ip_address).returns('208.90.212.38')
      @params = {
        :udid => 'stuff',
        :publisher_user_id => 'more_stuff',
        :currency_id => @currency.id,
        :app_id => @currency.app.id,
      }

    end

    describe "with promoted offers" do
      before :each do
        @partner = Factory(:partner)
        @app = Factory(:app, :partner => @partner)
        App.stubs(:find_in_cache).returns(@app)

        @offer1 = Factory(:app, :partner => @partner).primary_offer
        @offer2 = Factory(:app, :partner => @partner).primary_offer
        @offer3 = Factory(:app, :partner => @partner).primary_offer
        @offer4 = Factory(:app, :partner => @partner).primary_offer
        Offer.any_instance.stubs(:can_be_promoted?).returns(true)

        @global_promoted_offer = Factory(:global_promoted_offer, :partner => @partner, :offer => @offer2)
        @promoted_offer = Factory(:promoted_offer, :app => @app, :offer => @offer3)

        OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([ @offer1, @offer2, @offer3, @offer4 ])
      end

      it "should favor the cross promoted inventory" do
        get(:index, @params)
        offer_list = assigns(:offer_list)
        assert( offer_list == [ @offer2, @offer3, @offer1, @offer4 ] || offer_list == [ @offer3, @offer2, @offer1, @offer4 ] )
      end
    end

    it "should return json" do
      get(:index, @params.merge(:json => 1))
      should respond_with_content_type :json
      should render_template "get_offers/installs_json"
    end

    it "should render appropriate pages" do
      get(:index, @params.merge(:type => 0))
      should render_template "get_offers/offers"
      get(:index, @params.merge(:redirect => 1))
      should render_template "get_offers/installs_redirect"
      get(:index, @params)
      should render_template "get_offers/installs"
    end

    it "should have proper geoip data" do
      get(:index, @params.merge(:json => 1))
      assigns(:geoip_data).should be_empty
      get(:index, @params)
      assigns(:geoip_data).should_not be_empty
      get(:index, @params.merge(:json => 1, :device_ip => '208.90.212.38'))
      assigns(:geoip_data).should_not be_empty
      get(:index, @params.merge(:json => 1, :callback => 'wah!'))
      assigns(:geoip_data).should_not be_empty
      get(:index, @params.merge(:redirect => 1))
      assigns(:geoip_data).should be_empty
    end

    it "should return offers targeted to country" do
      get(:index, @params)
      assigns(:offer_list).should == [@offer, @offer3]
      controller.stubs(:get_geoip_data).returns({ :carrier_country_code => 'GB' })
      get(:index, @params)
      assigns(:offer_list).should == [@offer, @offer2]
    end

    it "should ignore country_code if IP is in China" do
      controller.stubs(:get_ip_address).returns('60.0.0.1')
      get(:index, @params)
      assigns(:offer_list).should == [@offer, @offer4]
      get(:index, @params.merge(:country_code => 'GB'))
      assigns(:offer_list).should == [@offer, @offer4]
    end

    it "should render json with correct fields" do
      get(:index, @params.merge(:json => 1))
      json = JSON.parse(response.body)

      json_offer = json['OfferArray'][0]
      json_offer['Cost'       ].should == 'Free'
      json_offer['Amount'     ].should == '5'
      json_offer['Name'       ].should == @offer.name
      json_offer['Payout'     ].should == 5
      json_offer['Type'       ].should == 'App'
      json_offer['StoreID'    ].should == @offer.store_id_for_feed
      json_offer['IconURL'    ].should be_present
      json_offer['RedirectURL'].should be_present

      json['CurrencyName'].should == 'TAPJOY_BUCKS'
      json['Message'].should == 'Install one of the apps below to earn TAPJOY_BUCKS'
    end

    it "should return FullScreenAdURL when rendering featured json" do
      get(:index, @params.merge(:json => 1, :source => 'featured'))
      json = JSON.parse(response.body)
      json['OfferArray'].should be_present
      json['OfferArray'][0]['FullScreenAdURL'].should be_present
    end

    it "should wrap json in a callback url when requesting jsonp" do
      get(:index, @params.merge(:json => 1, :source => 'featured',
                                :callback => '();callbackFunction'))
      match = response.body.match(/(^callbackFunction\()(.*)(\)$)/m)
      match.should_not be_nil
      json = JSON.parse(match[2])
      json['OfferArray'].should be_present
    end
  end

  describe "webpage" do
    before :each do
      @device = Factory(:device)
      @currency = Factory(:currency, :test_devices => @device.id)
      @currency.update_attribute(:hide_rewarded_app_installs, false)
      @params = {
        :udid => 'stuff',
        :publisher_user_id => 'more_stuff',
        :currency_id => @currency.id,
        :app_id => @currency.app.id
      }
      @offer = Factory(:app).primary_offer
    end

    it "should assign test offer for test devices" do
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])
      get(:webpage, @params.merge(:udid => @device.id))
      assigns(:test_offers).should_not be_nil
    end

    it "should not log impressions when there are no offers" do
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([])
      RailsCache.stubs(:get).returns(nil)
      get(:webpage, @params)
      assigns(:web_request).path.should include 'offers'
    end
  end

  describe "featured" do
    before :each do
      RailsCache.stubs(:get).returns(nil)
      @device = Factory(:device)
      @currency = Factory(:currency, :test_devices => @device.id)
      @currency.update_attribute(:hide_rewarded_app_installs, false)
      @offer = Factory(:app).primary_offer
      controller.stubs(:get_ip_address).returns('208.90.212.38')
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])
      @params = {
        :udid => 'stuff',
        :publisher_user_id => 'more_stuff',
        :currency_id => @currency.id,
        :app_id => @currency.app.id
      }
    end

    describe "with a featured offer" do
      before :each do
        get(:featured, @params)
      end

      it "should return the featured offer" do
        assigns(:web_request).offer_id.should == @offer.id
        assigns(:web_request).path.should include("featured_offer_shown")
      end

      it "should not have more data" do
        assigns(:more_data_available).should == 0
      end
    end

    describe "without a featured offer, but with a non-featured offer" do
      before :each do
        device_type = 'itouch'
        stub_args_1 = [
          Offer::FEATURED_OFFER_TYPE,
          @currency.app.platform_name,
          false,
          device_type,
        ]
        stub_args_2 = [
          Offer::FEATURED_BACKFILLED_OFFER_TYPE,
          @currency.app.platform_name,
          false,
          device_type,
        ]

        OfferCacher.stubs(:get_unsorted_offers_prerejected).with(*stub_args_1).once.returns([])
        OfferCacher.stubs(:get_unsorted_offers_prerejected).with(*stub_args_2).once.returns([@offer])

        get(:featured, @params)
      end

      it "should returns the non-featured offer" do
        assigns(:web_request).offer_id.should == @offer.id
        assigns(:web_request).path.should include("featured_offer_shown")
      end

      it "should not have more data" do
        assigns(:more_data_available).should == 0
      end
    end

    describe "without an offer" do
      before :each do
        OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([])
        RailsCache.stubs(:get).returns(nil)
        get(:featured, @params)
      end

      it "should return no offers" do
        assigns(:offer_list).should be_empty
        web_request = assigns(:web_request)
        web_request.offer_id.should be_nil
        web_request.path.should include 'featured_offer_requested'
        web_request.path.should_not include 'featured_offer_shown'
      end
    end

    it "should assign test offer for test devices" do
      get(:featured, @params.merge(:udid => @device.id))
      assigns(:offer_list).first.item_type.should == "TestOffer"
      assigns(:offer_list).length.should == 1
    end

    it "should render appropriate views" do
      get(:featured, @params)
      should render_template "get_offers/installs_redirect"

      get(:featured, @params.merge(:json => 1))
      should render_template "get_offers/installs_json"
      response.content_type.should == "application/json"
    end

    it "should have proper geoip data" do
      get(:featured, @params)
      assert !assigns(:geoip_data).empty?
    end
  end

  describe "setup" do
    before :each do
      @device = Factory(:device)
      @currency = Factory(:currency)
      @offer = Factory(:app).primary_offer
      controller.stubs(:get_ip_address).returns('208.90.212.38')
      fake_cache_object = mock()
      fake_cache_object.stubs(:value).returns([@offer])
      RailsCache.stubs(:get_and_put).returns(fake_cache_object)
      @params = {
        :udid => @device.id,
        :publisher_user_id => 'more_stuff',
        :currency_id => @currency.id,
        :app_id => @currency.app.id
      }
      get(:index, @params)
    end

    it "should assign web_request" do
      get(:index, @params.merge(:exp => 10))
      web_request = assigns(:web_request)
      assigns(:now).to_s.should == web_request.viewed_at.to_s
      web_request.exp.should == '10'
      web_request.user_agent.should == @request.headers["User-Agent"]
      web_request.ip_address.should == '208.90.212.38'
      web_request.source.should == 'offerwall'
      web_request.offerwall_rank.should == 1
      web_request.path.should include('offerwall_impression')

      get(:featured, @params)
      web_request = assigns(:web_request)
      web_request.path.should include('featured_offer_requested')
      web_request.path.should include('featured_offer_shown')
    end

    it "should assign max_items" do
      assigns(:max_items).should == 25

      get(:index, @params.merge(:max => 5))
      assigns(:max_items).should == 5
    end

    it "should assign currency" do
      assigns(:currency).should == @currency
    end

    it "should assign currencies" do
      get(:index, @params.merge(:currency_selector => '1'))
      assigns(:currency).should == @currency
      assigns(:currencies).should_not be_nil
    end

    it "should unassign currency" do
      app = Factory(:app)
      get(:index, @params.merge(:app_id => app.id))
      assigns(:currency).should be_nil
    end

    it "should assign currency based on app_id" do
      Factory(:currency, :id => @currency.app_id, :app_id => @currency.app_id)
      get(:index, @params.merge(:currency_id => nil, :debug => '1'))
      assigns(:currency).should_not be_nil
    end

    it "should assign start_index" do
      assigns(:device).key.should == @device.key
      assigns(:start_index).should == 0

      get(:index, @params.merge(:start => 2))
      assigns(:start_index).should == 2
    end

  end
end
