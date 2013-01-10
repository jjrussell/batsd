require 'spec_helper'

describe GetOffersController do
  render_views

  describe '#index' do
    before :each do
      Timecop.freeze(Time.parse('2012-08-01')) # forcing new spend share algorithm
      @currency = FactoryGirl.create(:currency)
      @currency.update_attributes({:external_publisher => true})
      @deeplink = @currency.deeplink_offer.primary_offer
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.partner.balance = 10
      @offer.save
      @offer2 = FactoryGirl.create(:app).primary_offer
      @offer2.countries = ["GB"].to_json
      @offer2.partner.balance = 10
      @offer2.save
      @offer3 = FactoryGirl.create(:app).primary_offer
      @offer3.countries = ["US"].to_json
      @offer3.partner.balance = 10
      @offer3.save
      @offer4 = FactoryGirl.create(:app).primary_offer
      @offer4.countries = ["CN"].to_json
      @offer4.partner.balance = 10
      @offer4.save

      @deeplink.cache
      Currency.stub(:find_in_cache).and_return(@currency)
      @currency.stub(:active_and_future_sales).and_return({})
      App.stub(:find_in_cache).and_return(@currency.app)

      offers = [ @offer, @offer2, @offer3, @offer4 ]
      offers.each &:cache
      OfferCacher.stub(:get_offers_prerejected).and_return(offers)
      RailsCache.stub(:get).and_return(nil)
      controller.stub(:ip_address).and_return('208.90.212.38')
      @params = {
        :udid => 'stuff',
        :publisher_user_id => 'more_stuff',
        :currency_id => @currency.id,
        :app_id => @currency.app.id,
      }
    end

    after :each do
      Timecop.return
    end

    it 'should queue up tracking url calls' do
      @offer.should_receive(:queue_impression_tracking_requests).with(
        :ip_address       => @controller.send(:ip_address),
        :udid             => 'stuff',
        :publisher_app_id => @currency.app.id).once

      get(:index, @params)
    end

    it 'should mark the pub app as using non-html responses' do
      message = { :class_name => 'App', :id => @currency.app.id, :attributes => { :uses_non_html_responses => true } }
      Sqs.should_receive(:send_message).with(QueueNames::RECORD_UPDATES, Base64::encode64(Marshal.dump(message))).once

      get(:index, @params)
    end

    # TODO: Make promoted offers work with optmization
    # describe "with promoted offers" do
    #   before :each do
    #     @partner = FactoryGirl.create(:partner)
    #     @app = FactoryGirl.create(:app, :partner => @partner)
    #
    #     @offer1 = FactoryGirl.create(:app, :partner => @partner).primary_offer
    #     @offer2 = FactoryGirl.create(:app, :partner => @partner).primary_offer
    #     @offer3 = FactoryGirl.create(:app, :partner => @partner).primary_offer
    #     @offer4 = FactoryGirl.create(:app, :partner => @partner).primary_offer
    #     @offer5 = FactoryGirl.create(:app, :partner => @partner).primary_offer
    #
    #     App.stub(:find_in_cache).and_return(@app)
    #     Currency.stub(:find_in_cache).and_return(@currency)
    #   end
    #
    #   it "favors the promoted inventory" do
    #     @currency.stub(:partner_get_promoted_offers).and_return([@offer2.id])
    #     @currency.stub(:get_promoted_offers).and_return([@offer3.id])
    #     OfferCacher.stub(:get_offers_prerejected).and_return([@offer1, @offer2, @offer3, @offer4, @offer5])
    #
    #     get(:index, @params)
    #     offer_list = assigns(:offer_list)
    #     assert( offer_list == [ @offer2, @offer3, @offer1, @offer4, @offer5 ] || offer_list == [ @offer3, @offer2, @offer1, @offer4, @offer5 ] )
    #   end
    #
    #   it "restricts the number of slots used for promotion" do
    #     @offer3.stub(:rank_score).and_return(1004)
    #     @currency.stub(:get_promoted_offers).and_return([@offer1.id, @offer2.id, @offer5.id, @offer4.id])
    #     OfferCacher.stub(:get_offers_prerejected).and_return([@offer1, @offer2, @offer3, @offer4, @offer5])
    #
    #     get(:index, @params)
    #     assigns(:offer_list)[3].rank_score.should == 1004
    #   end
    # end

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
      assigns(:offer_list).should == [@offer, @offer3, @deeplink]
      controller.stub(:geoip_data).and_return({ :primary_country => 'GB' })
      get(:index, @params)
      assigns(:offer_list).should == [@offer, @offer2, @deeplink]
    end

    context 'when the same app has multiple offers' do
      it 'returns only the highest ranked offer' do
        app = FactoryGirl.create(:app)
        offer1 = app.primary_offer
        offer1.partner.balance = 10
        offer2 = offer1.clone
        offer2.save
        offer2.partner.balance = 10
        offer3 = offer1.clone
        offer3.save
        offer3.partner.balance = 10
        offer4 = offer1.clone
        offer4.save
        offer4.partner.balance = 10
        OfferCacher.stub(:get_offers_prerejected).and_return([ offer1, offer2, offer3, offer4 ])

        [app, offer1, offer2, offer3, offer4].each &:cache

        get(:index, @params)
        assigns(:offer_list).include?([offer2, offer3, offer4]).should be_false
        assigns(:offer_list).include?(offer1).should be_true
      end
    end

    context 'when targeting app stores' do
      before :each do
        publisher_app = FactoryGirl.create(:app, :platform => 'android')
        publisher_app.add_app_metadata('android.GFan', 'def789')
        @currency = FactoryGirl.create(:currency, :app => publisher_app)

        @offer1 = FactoryGirl.create(:generic_offer).primary_offer
        @offer1.partner.balance = 10
        @offer1.update_attributes!(:payment => 10)

        @offer2 = FactoryGirl.create(:app, :platform => 'android').primary_offer
        @offer2.partner.balance = 10

        app = FactoryGirl.create(:app, :platform => 'android')
        metadata = app.add_app_metadata('android.GFan', 'xyz123')
        @offer3 = app.offers.find_by_app_metadata_id(metadata.id)
        @offer3.partner.balance = 10

        [@offer1, @offer2, @offer3, @currency, @currency.app].each &:cache

        OfferCacher.stub(:get_offers_prerejected).and_return([ @offer1, @offer2, @offer3 ])
        Currency.stub(:find_in_cache).and_return(@currency)
        App.stub(:find_in_cache).and_return(@currency.app)
        @params = {
          :udid => 'stuff',
          :publisher_user_id => 'more_stuff',
          :currency_id => @currency.id,
          :app_id => @currency.app.id,
        }
      end

      it 'returns all offers by default' do
        AppStore.find('android.GooglePlay').stub(:exclusive?).and_return(false)
        get(:index, @params)
        assigns(:offer_list).should == [@offer1, @offer2, @offer3]
      end

      it 'returns targeted offers for exclusive stores' do
        @params[:store_name] = 'gfan'
        get(:index, @params)
        assigns(:offer_list).should == [@offer1, @offer3]
      end

      it 'returns targeted offers for currency store whitelist' do
        AppStore.find('android.GooglePlay').stub(:exclusive?).and_return(true)
        get(:index, @params)
        assigns(:offer_list).map(&:id).should == [@offer1, @offer2].map(&:id)
      end
    end

    it 'ignores country_code if IP is in China' do
      controller.stub(:ip_address).and_return('60.0.0.1')
      get(:index, @params)
      assigns(:offer_list).should == [@offer, @offer4, @deeplink]
      get(:index, @params.merge(:country_code => 'GB'))
      assigns(:offer_list).should == [@offer, @offer4, @deeplink]
    end

    it 'renders json with correct fields' do
      get(:index, @params.merge(:json => '1'))
      json = JSON.parse(response.body)

      json_offer = json['OfferArray'][0]
      json_offer['Cost'       ].should == 'Free'
      json_offer['isFree'     ].should == true
      json_offer['Amount'     ].should == '4'
      json_offer['Name'       ].should == @offer.name
      json_offer['Payout'     ].should == 4
      json_offer['Type'       ].should == 'App'
      json_offer['StoreID'    ].should == @offer.store_id_for_feed
      json_offer['IconURL'    ].should be_present
      json_offer['RedirectURL'].should be_present

      json['CurrencyName'].should == @currency.name
      json['Message'].should == "Install one of the apps below to earn #{@currency.name}"
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
      @device = FactoryGirl.create(:device)
      @currency = FactoryGirl.create(:currency, :test_devices => @device.id)
      @currency.update_attribute(:hide_rewarded_app_installs, false)
      @params = {
        :udid => 'stuff',
        :publisher_user_id => 'more_stuff',
        :currency_id => @currency.id,
        :app_id => @currency.app.id
      }
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.partner.balance = 10
      @offer.save
      Currency.stub(:find_in_cache).and_return(@currency)
      App.stub(:find_in_cache).and_return(@currency.app)
      Offer.stub(:find_in_cache).and_return(@offer)
      @currency.stub(:active_and_future_sales).and_return({})
    end

    context 'with redesign specified' do
      before :each do
        @params.merge!(:redesign => 'true')
      end

      context 'with json=1' do
        before :each do
          @params.merge!(:json => '1')
        end

        it 'should mark the pub app as using non-html responses' do
          message = { :class_name => 'App', :id => @currency.app.id, :attributes => { :uses_non_html_responses => true } }
          Sqs.should_receive(:send_message).with(QueueNames::RECORD_UPDATES, Base64::encode64(Marshal.dump(message))).once

          get(:index, @params)
        end
      end
    end

    it 'should set for_preview if an offer_id is provided' do
      get(:webpage, @params.merge(:offer_id => @offer.id))
      assigns[:for_preview].should == true
    end

    it 'should queue up tracking url calls' do
      OfferCacher.stub(:get_offers_prerejected).and_return([@offer])
      @offer.should_receive(:queue_impression_tracking_requests).with(
        :ip_address       => @controller.send(:ip_address),
        :udid             => 'stuff',
        :publisher_app_id => @currency.app.id).once

      get(:webpage, @params)
    end

    context "test offers" do
      before :each do
        OfferCacher.stub(:get_offers_prerejected).and_return([@offer])
        @params.merge!(:udid => @device.id)
      end

      it 'assigns test offer for test devices', :test_offers do
        get(:webpage, @params)
        assigns(:test_offers).should_not be_nil
      end

      it 'shows test video offer for SDK >= 8.3', :test_offers do
        get(:webpage, @params.merge(:library_version => "8.3"))
        assigns(:test_offers).map(&:id).include?('test_video').should be_true
      end

      it 'does not shows test video offer for SDK < 8.3', :test_offers do
        get(:webpage, @params.merge(:library_version => "8.2"))
        assigns(:test_offers).map(&:id).include?('test_video').should be_false
      end

      it 'shows test video offer for SDK < 8.3 if all_videos param is present', :test_offers do
        get(:webpage, @params.merge(:library_version => "8.2", :all_videos => '1'))
        assigns(:test_offers).map(&:id).include?('test_video').should be_true
      end

      it 'shows test video offer for SDK < 8.3 if video_offer_ids includes test_video', :test_offers do
        get(:webpage, @params.merge(:library_version => "8.2", :video_offer_ids => 'test_video'))
        assigns(:test_offers).map(&:id).include?('test_video').should be_true
      end
    end

    it 'does not log impressions when there are no offers' do
      OfferCacher.stub(:get_offers_prerejected).and_return([])
      RailsCache.stub(:get).and_return(nil)
      @currency.deeplink_offer.primary_offer.tapjoy_enabled = false
      @currency.deeplink_offer.primary_offer.save!
      get(:webpage, @params)
      assigns(:web_request).path.should include 'offers'
    end
  end

  describe '#featured' do
    context "empty offer list" do
      before :each do
        RailsCache.stub(:get).and_return(nil)
        @device = FactoryGirl.create(:device)
        @currency = FactoryGirl.create(:currency, :test_devices => @device.id)
        @currency.update_attribute(:hide_rewarded_app_installs, false)

        OfferCacher.stub(:get_offers_prerejected).and_return([])
        @params = {
          :udid => 'stuff',
          :format => 'html',
          :publisher_user_id => 'more_stuff',
          :currency_id => @currency.id,
          :app_id => @currency.app.id
        }
        Currency.stub(:find_in_cache).and_return(@currency)
        App.stub(:find_in_cache).and_return(@currency.app)
        @currency.stub(:active_and_future_sales).and_return({})
      end

      context "library version >= 9.0" do
        it "should return non-200 status code", :empty_offer_list do
          @params.merge!({:library_version => "9.0"})
          get(:featured, @params)
          response.response_code.should == 501
        end
      end

      context "library version <= 9.0" do
        it "should return non-200 status code", :empty_offer_list do
          @params.merge!({:library_version => "8.3"})
          get(:featured, @params)
          response.response_code.should == 200
        end

        it "should return non-200 status code", :empty_offer_list do
          @params.merge!({:library_version => "8.3"})
          get(:featured, @params)
          response.body.should == ""
        end
      end
    end

    context "non-empty offer list" do
      before :each do
        RailsCache.stub(:get).and_return(nil)
        @device = FactoryGirl.create(:device)
        @currency = FactoryGirl.create(:currency, :test_devices => @device.id)
        @currency.update_attribute(:hide_rewarded_app_installs, false)
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.partner.balance = 10
        @offer.save
        controller.stub(:ip_address).and_return('208.90.212.38')
        OfferCacher.stub(:get_offers_prerejected).and_return([@offer])
        @params = {
          :udid => 'stuff',
          :publisher_user_id => 'more_stuff',
          :currency_id => @currency.id,
          :app_id => @currency.app.id
        }
        Currency.stub(:find_in_cache).and_return(@currency)
        App.stub(:find_in_cache).and_return(@currency.app)
        @currency.stub(:active_and_future_sales).and_return({})
      end

      it 'should mark the pub app as using non-html responses' do
        message = { :class_name => 'App', :id => @currency.app.id, :attributes => { :uses_non_html_responses => true } }
        Sqs.should_receive(:send_message).with(QueueNames::RECORD_UPDATES, Base64::encode64(Marshal.dump(message))).once

        get(:index, @params)
      end

      context 'previewing featured ads' do
        it 'should set for_preview if an offer_id is provided' do
          get(:featured, @params.merge(:offer_id => @offer.id, :format => 'html'))
          assigns[:for_preview].should == true
        end

        it 'should merge in offer overrides for preview' do
          get(:featured, @params.merge(
            :format => 'html',
            :offer_id => @offer.id,
            :offer_preview_attributes => {
              :featured => 'true',
              :featured_ad_action => 'My Action',
              :featured_ad_content => 'My Content',
              :featured_ad_color => 'my_color'
            }))

          assigns[:offer].featured_ad_content.should == 'My Content'
          assigns[:offer].featured_ad_action.should == 'My Action'
          assigns[:offer].featured_ad_color.should == 'my_color'
          assigns[:offer].featured.should == true
        end

        it 'should not save offer overrides for preview' do
          get(:featured, @params.merge(
            :format => 'html',
            :offer_id => @offer.id,
            :offer_preview_attributes => {
              :featured => 'true',
              :featured_ad_action => 'My Action',
              :featured_ad_content => 'My Content',
              :featured_ad_color => 'my_color'
            }))

          ActiveRecordDisabler.with_queries_enabled { @offer.reload }

          @offer.featured_ad_content.should_not == 'My Content'
          @offer.featured_ad_action.should_not == 'My Action'
          @offer.featured_ad_color.should_not == 'my_color'
          @offer.featured.should_not == true
        end
      end

      context 'with a featured offer' do
        before :each do
          get(:featured, @params)
        end

        it 'returns the featured offer', :featured do
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

          OfferCacher.stub(:get_offers_prerejected).with(*stub_args_1).once.and_return([])
          OfferCacher.stub(:get_offers_prerejected).with(*stub_args_2).once.and_return([@offer])

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
          OfferCacher.stub(:get_offers_prerejected).and_return([])
          RailsCache.stub(:get).and_return(nil)
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

      it 'renders tags for XNA' do
        get(:featured, @params)
        should render_template "get_offers/installs_redirect"
        response.content_type.should == "application/xml"
        # TODO: fix these
        #response.should have_tag('OfferText')
        #response.should have_tag('EarnCurrencyText')
        #response.should have_tag('ActionText')
        #response.should have_tag('CustomCreative')
        #response.should have_tag('SkipText')
      end
    end
  end

  describe '#setup' do
    before :each do
      @device = FactoryGirl.create(:device)
      @currency = FactoryGirl.create(:currency, :callback_url => 'http://www.tapjoy.com')
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.partner.balance = 10
      controller.stub(:ip_address).and_return('208.90.212.38')
      fake_cache_object = double('fake_cache_object')
      fake_cache_object.stub(:value).and_return([@offer])
      RailsCache.stub(:get_and_put).and_return(fake_cache_object)
      @params = {
        :udid => @device.id,
        :publisher_user_id => 'more_stuff',
        :currency_id => @currency.id,
        :app_id => @currency.app.id,
        :type => Offer::CLASSIC_OFFER_TYPE
      }

      [@offer, @currency].each &:cache

      Currency.stub(:find_in_cache).and_return(@currency)
      @currency.stub(:active_and_future_sales).and_return({})
      App.stub(:find_in_cache).and_return(@currency.app)
      get(:index, @params)
    end

    it 'assigns web_request' do
      get(:index, @params)
      web_request = assigns(:web_request)
      assigns(:now).to_s.should == web_request.viewed_at.to_s
      web_request.user_agent.should == @request.headers["User-Agent"]
      web_request.ip_address.should == '208.90.212.38'
      web_request.source.should == 'offerwall'
      web_request.offerwall_rank.should == nil
      web_request.path.should include('offers')

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
      app = ActiveRecordDisabler.with_queries_enabled { FactoryGirl.create(:app) }
      get(:index, @params.merge(:app_id => app.id))
      assigns(:currency).should be_nil
    end

    it 'assigns currency based on app_id' do
      ActiveRecordDisabler.with_queries_enabled do
        currency = FactoryGirl.create(:currency, :id => @currency.app_id, :app_id => @currency.app_id, :callback_url => 'http://www.tapjoy.com')
        currency.cache
      end

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

    context 'when the accessing SDK supports video cache controls' do
      before(:each) do
        controller.stub(:library_version => mock(:control_video_caching? => true))
      end

      it "should respect the hide_videos parameter" do
        get(:index, @params.merge(:hide_videos => 'true', :video_offer_ids => 'abc,123'))
        assigns(:video_offer_ids).should be_empty

        get(:index, @params.merge(:hide_videos => 'false', :video_offer_ids => 'abc,123'))
        assigns(:video_offer_ids).should == ['abc', '123']
      end

      it 'respects the apps streaming setting' do
        app = ActiveRecordDisabler.with_queries_enabled { App.find(@params[:app_id]) }
        App.stub(:find_in_cache => app)
        ActiveRecordDisabler.with_queries_enabled { app.update_attributes(:videos_stream_3g => true) }

        get(:index, @params.merge(:connection_type => 'mobile'))
        assigns(:all_videos).should be_true

        ActiveRecordDisabler.with_queries_enabled { app.update_attributes(:videos_stream_3g => false) }
        get(:index, @params.merge(:connection_type => 'mobile'))
        assigns(:all_videos).should be_false
      end
    end
  end
end
