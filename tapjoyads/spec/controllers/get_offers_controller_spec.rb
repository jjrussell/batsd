require 'spec/spec_helper'

describe GetOffersController do
  render_views

  before :each do
    fake_the_web
  end

  describe '#index' do
    before :each do
      @currency = Factory(:currency)
      @deeplink = @currency.deeplink_offer.primary_offer
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
      controller.stubs(:ip_address).returns('208.90.212.38')
      @params = {
        :udid => 'stuff',
        :publisher_user_id => 'more_stuff',
        :currency_id => @currency.id,
        :app_id => @currency.app.id,
      }

    end

    it 'should queue up tracking url calls' do
      @offer.expects(:queue_impression_tracking_requests).once

      get(:index, @params)
    end

    describe "with promoted offers" do
      before :each do
        @partner = Factory(:partner)
        @app = Factory(:app, :partner => @partner)

        @offer1 = Factory(:app, :partner => @partner).primary_offer
        @offer2 = Factory(:app, :partner => @partner).primary_offer
        @offer3 = Factory(:app, :partner => @partner).primary_offer
        @offer4 = Factory(:app, :partner => @partner).primary_offer
        @offer5 = Factory(:app, :partner => @partner).primary_offer

        App.stubs(:find_in_cache).returns(@app)
        Currency.stubs(:find_in_cache).returns(@currency)
      end

      it "favors the promoted inventory" do
        @currency.stubs(:partner_get_promoted_offers).returns([@offer2.id])
        @currency.stubs(:get_promoted_offers).returns([@offer3.id])
        OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer1, @offer2, @offer3, @offer4, @offer5])

        get(:index, @params)
        offer_list = assigns(:offer_list)
        assert( offer_list == [ @offer2, @offer3, @offer1, @offer4, @offer5 ] || offer_list == [ @offer3, @offer2, @offer1, @offer4, @offer5 ] )
      end

      it "restricts the number of slots used for promotion" do
        @offer3.stubs(:rank_score).returns(1004)
        @currency.stubs(:get_promoted_offers).returns([@offer1.id, @offer2.id, @offer5.id, @offer4.id])
        OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer1, @offer2, @offer3, @offer4, @offer5])

        get(:index, @params)
        assigns(:offer_list)[3].rank_score.should == 1004
      end
    end

    it 'returns json' do
      get(:index, @params.merge(:json => '1'))
      should respond_with_content_type :json
      should render_template "get_offers/installs_json"
    end

    it 'renders appropriate pages' do
      get(:index, @params.merge(:type => '0'))
      should render_template "get_offers/offers"
      get(:index, @params.merge(:redirect => '1'))
      should render_template "get_offers/installs_redirect"
      get(:index, @params)
      should render_template "get_offers/installs"
    end

    it 'returns offers targeted to country' do
      get(:index, @params)
      assigns(:offer_list).should == [@deeplink, @offer, @offer3]
      controller.stubs(:geoip_data).returns({ :primary_country => 'GB' })
      get(:index, @params)
      assigns(:offer_list).should == [@deeplink, @offer, @offer2]
    end

    it 'ignores country_code if IP is in China' do
      controller.stubs(:ip_address).returns('60.0.0.1')
      get(:index, @params)
      assigns(:offer_list).should == [@deeplink, @offer, @offer4]
      get(:index, @params.merge(:country_code => 'GB'))
      assigns(:offer_list).should == [@deeplink, @offer, @offer4]
    end

    it 'renders json with correct fields' do
      get(:index, @params.merge(:json => '1'))
      json = JSON.parse(response.body)

      json_offer = json['OfferArray'][1]
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

    it 'returns FullScreenAdURL when rendering featured json' do
      get(:index, @params.merge(:json => '1', :source => 'featured'))
      json = JSON.parse(response.body)
      json['OfferArray'].should be_present
      json['OfferArray'][0]['FullScreenAdURL'].should be_present
    end

    it 'wraps json in a callback url when requesting jsonp' do
      get(:index, @params.merge(:json => '1', :source => 'featured',
                                :callback => '();callbackFunction'))
      match = response.body.match(/(^callbackFunction\()(.*)(\)$)/m)
      match.should_not be_nil
      json = JSON.parse(match[2])
      json['OfferArray'].should be_present
    end
  end

  describe '#webpage' do
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

    context 'with third party tracking URLs' do
      it 'should generate hidden image tags' do
        url = "https://dummyurl.com"
        @offer.third_party_tracking_urls = [url]
        @offer.save!

        OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])
        get(:webpage, @params)

        response.body.should include("<img t='https://dummyurl.com' />")
      end
    end

    it 'assigns test offer for test devices' do
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])
      get(:webpage, @params.merge(:udid => @device.id))
      assigns(:test_offers).should_not be_nil
    end

    it 'does not log impressions when there are no offers' do
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([])
      RailsCache.stubs(:get).returns(nil)
      @currency.deeplink_offer.primary_offer.tapjoy_enabled = false
      @currency.deeplink_offer.primary_offer.save!
      get(:webpage, @params)
      assigns(:web_request).path.should include 'offers'
    end
  end

  describe '#featured' do
    before :each do
      RailsCache.stubs(:get).returns(nil)
      @device = Factory(:device)
      @currency = Factory(:currency, :test_devices => @device.id)
      @currency.update_attribute(:hide_rewarded_app_installs, false)
      @offer = Factory(:app).primary_offer
      controller.stubs(:ip_address).returns('208.90.212.38')
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])
      @params = {
        :udid => 'stuff',
        :publisher_user_id => 'more_stuff',
        :currency_id => @currency.id,
        :app_id => @currency.app.id
      }
    end

    context 'with a featured offer' do
      before :each do
        get(:featured, @params)
      end

      it 'returns the featured offer' do
        assigns(:web_request).offer_id.should == @offer.id
        assigns(:web_request).path.should include("featured_offer_shown")
      end

      it 'does not have more data' do
        assigns(:more_data_available).should == 0
      end
    end

    context 'without a featured offer, but with a non-featured offer' do
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

      it 'returns the non-featured offer' do
        assigns(:web_request).offer_id.should == @offer.id
        assigns(:web_request).path.should include("featured_offer_shown")
      end

      it 'does not have more data' do
        assigns(:more_data_available).should == 0
      end
    end

    context 'without an offer' do
      before :each do
        OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([])
        RailsCache.stubs(:get).returns(nil)
        get(:featured, @params)
      end

      it 'returns no offers' do
        assigns(:offer_list).should be_empty
        web_request = assigns(:web_request)
        web_request.offer_id.should be_nil
        web_request.path.should include 'featured_offer_requested'
        web_request.path.should_not include 'featured_offer_shown'
      end
    end

    it 'assigns test offer for test devices' do
      get(:featured, @params.merge(:udid => @device.id))
      assigns(:offer_list).first.item_type.should == "TestOffer"
      assigns(:offer_list).length.should == 1
    end

    it 'renders appropriate views' do
      get(:featured, @params)
      should render_template "get_offers/installs_redirect"

      get(:featured, @params.merge(:json => '1'))
      should render_template "get_offers/installs_json"
      response.content_type.should == "application/json"
    end
  end

  describe '#setup' do
    before :each do
      @device = Factory(:device)
      @currency = Factory(:currency, :callback_url => 'http://www.tapjoy.com')
      @offer = Factory(:app).primary_offer
      controller.stubs(:ip_address).returns('208.90.212.38')
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

    it 'assigns web_request' do
      get(:index, @params.merge(:exp => 10))
      web_request = assigns(:web_request)
      assigns(:now).to_s.should == web_request.viewed_at.to_s
      web_request.exp.should == '10'
      web_request.user_agent.should == @request.headers["User-Agent"]
      web_request.ip_address.should == '208.90.212.38'
      web_request.source.should == 'offerwall'
      web_request.offerwall_rank.should == 2
      web_request.path.should include('offerwall_impression')

      get(:featured, @params)
      web_request = assigns(:web_request)
      web_request.path.should include('featured_offer_requested')
      web_request.path.should include('featured_offer_shown')
    end

    it 'assigns max_items' do
      assigns(:max_items).should == 25

      get(:index, @params.merge(:max => 5))
      assigns(:max_items).should == 5
    end

    it 'assigns currency' do
      assigns(:currency).should == @currency
    end

    it 'assigns currencies' do
      get(:index, @params.merge(:currency_selector => '1'))
      assigns(:currency).should == @currency
      assigns(:currencies).should_not be_nil
    end

    it 'unassigns currency' do
      app = Factory(:app)
      get(:index, @params.merge(:app_id => app.id))
      assigns(:currency).should be_nil
    end

    it 'assigns currency based on app_id' do
      Factory(:currency, :id => @currency.app_id, :app_id => @currency.app_id, :callback_url => 'http://www.tapjoy.com')
      get(:index, @params.merge(:currency_id => nil, :debug => '1'))
      assigns(:currency).should_not be_nil
    end

    it 'assigns start_index' do
      assigns(:device).key.should == @device.key
      assigns(:start_index).should == 0

      get(:index, @params.merge(:start => 2))
      assigns(:start_index).should == 2
    end

    it "should identify server-to-server calls" do
      get(:index, @params.merge(:json => '1'))
      assigns(:server_to_server).should == true
      get(:index, @params)
      assigns(:server_to_server).should == false
      get(:index, @params.merge(:json => '1', :callback => 'wah!'))
      assigns(:server_to_server).should == false
      get(:index, @params.merge(:redirect => '1'))
      assigns(:server_to_server).should == true
      get(:featured, @params)
      assigns(:server_to_server).should == false
      get(:featured, @params.merge(:json => '1'))
      assigns(:server_to_server).should == false
      get(:webpage, @params)
      assigns(:server_to_server).should == false
      get(:index, {:data => ObjectEncryptor.encrypt(@params.merge(:json => '1')) } )
      assigns(:server_to_server).should == false
      get(:webpage, @params.merge(:library_version => 'SERVER'))
      assigns(:server_to_server).should == true
    end
  end
end
