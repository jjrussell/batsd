require 'test_helper'

class GetOffersControllerTest < ActionController::TestCase
  context "when calling 'index'" do
    setup do
      @currency = Factory(:currency)
      @offer = Factory(:app).primary_offer
      @offer2 = Factory(:app).primary_offer
      @offer2.countries = ["GB"].to_json
      @offer2.save
      @offer3 = Factory(:app).primary_offer
      @offer3.countries = ["US"].to_json
      @offer3.save
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer, @offer2, @offer3])
      RailsCache.stubs(:get).returns(nil)
      controller.stubs(:get_ip_address).returns('208.90.212.38')
      @params = { :udid => 'stuff', :publisher_user_id => 'more_stuff', :currency_id => @currency.id, :app_id => @currency.app.id }
      @response = get(:index, @params.merge(:json => 1))
    end

    should respond_with_content_type(:json)

    should "render appropriate pages" do
      assert_template "get_offers/installs_json"
      @response = get(:index, @params.merge(:type => 0))
      assert_template "get_offers/offers"
      @response = get(:index, @params.merge(:redirect => 1))
      assert_template "get_offers/installs_redirect"
      @response = get(:index, @params)
      assert_template "get_offers/installs"
    end

    should "have proper geoip data" do
      @response = get(:index, @params.merge(:json => 1))
      assert assigns(:geoip_data).empty?
      @response = get(:index, @params)
      assert !assigns(:geoip_data).empty?
      @response = get(:index, @params.merge(:json => 1, :device_ip => '208.90.212.38'))
      assert !assigns(:geoip_data).empty?
      @response = get(:index, @params.merge(:json => 1, :callback => 'wah!'))
      assert !assigns(:geoip_data).empty?
      @response = get(:index, @params.merge(:redirect => 1))
      assert assigns(:geoip_data).empty?
    end

    should "return offers targeted to country" do
      @response = get(:index, @params)
      assert_equal [@offer, @offer3], assigns(:offer_list)
      @response = get(:index, @params.merge(:country_code => 'GB'))
      assert_equal [@offer, @offer2], assigns(:offer_list)
    end
    
    should "render json with correct fields" do
      json = JSON.parse(@response.body)
      assert json['OfferArray'].present?
      assert_equal 'Free', json['OfferArray'][0]['Cost']
      assert_equal '17', json['OfferArray'][0]['Amount']
      assert_equal @offer.name, json['OfferArray'][0]['Name']
      assert_equal 17, json['OfferArray'][0]['Payout']
      assert_equal "App", json['OfferArray'][0]['Type']
      assert_equal @offer.store_id_for_feed, json['OfferArray'][0]['StoreID']
      assert json['OfferArray'][0]['IconURL'].present?
      assert json['OfferArray'][0]['RedirectURL'].present?
      
      assert_equal 'TAPJOY_BUCKS', json['CurrencyName']
      assert_equal 'Install one of the apps below to earn TAPJOY_BUCKS', json['Message']
    end
    
    should "return FullScreenAdURL when rendering featured json" do
      @response = get(:index, @params.merge(:json => 1, :source => 'featured'))
      json = JSON.parse(@response.body)
      assert json['OfferArray'].present?
      assert json['OfferArray'][0]['FullScreenAdURL'].present?
    end
    
    should "wrap json in a callback url when requesting jsonp" do
      @response = get(:index, @params.merge(:json => 1, :source => 'featured', :callback => '();callbackFunction'))
      match = @response.body.match(/(^callbackFunction\()(.*)(\)$)/m)
      assert_equal 'callbackFunction(', match[1], "JSONP response should start with callback function"
      assert_equal ')', match[3], "JSONP response should end with callback paran"
      json = JSON.parse(match[2])
      assert json['OfferArray'].present?
    end
  end

  context "when calling 'webpage'" do
    setup do
      @device = Factory(:device)
      @currency = Factory(:currency, :test_devices => @device.id)
      @params = { :udid => 'stuff', :publisher_user_id => 'more_stuff', :currency_id => @currency.id, :app_id => @currency.app.id }
      @offer = Factory(:app).primary_offer
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])
    end

    should "assign test offer for test devices" do
      @response = get(:webpage, @params.merge(:udid => @device.id))
      assert assigns(:test_offer)
    end

    should "render redesign for appropriate devices" do
      @response = get(:webpage, @params.merge(:udid => @device.id))
      assert_template "get_offers/webpage.html.haml"

      device = Device.new(:key => 'a100000d9833c5')
      @response = get(:webpage, @params.merge(:udid => device.id))
      assert_template "get_offers/webpage_redesign_2"
      assert_equal "layouts/offerwall_redesign_2", @response.layout

      @currency.hide_rewarded_app_installs = true
      @currency.save!
      @response = get(:webpage, @params.merge(:udid => @device.id))
      assert_template "get_offers/webpage_redesign"
      assert_equal "layouts/iphone_redesign", @response.layout

      @response = get(:webpage, @params.merge(:source => "tj_games"))
      assert_template "get_offers/webpage.html.haml"

      @currency.minimum_hide_rewarded_app_installs_version = "15"
      @currency.save!
      @response = get(:webpage, @params.merge(:app_version => "14"))
      assert_template "get_offers/webpage.html.haml"
      @response = get(:webpage, @params.merge(:app_version => "16"))
      assert_template "get_offers/webpage_redesign.html.haml"
    end
  end

  context "when calling 'featured'" do
    setup do
      @device = Factory(:device)
      @currency = Factory(:currency, :test_devices => @device.id)
      @offer = Factory(:app).primary_offer
      controller.stubs(:get_ip_address).returns('208.90.212.38')
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])
      @params = { :udid => 'stuff', :publisher_user_id => 'more_stuff', :currency_id => @currency.id, :app_id => @currency.app.id }
    end

    should "assign test offer for test devices" do
      @response = get(:featured, @params.merge(:udid => @device.id))
      assert assigns(:offer_list).first.item_type == "TestOffer"
      assert assigns(:offer_list).length == 1
    end

    should "render appropriate views" do
      @response = get(:featured, @params)
      assert_template "get_offers/installs_redirect"

      @response = get(:featured, @params.merge(:json => 1))
      assert_template "get_offers/installs_json"
      assert_equal "application/json", @response.content_type
    end

    should "have offers" do
      @response = get(:featured, @params)
      assert assigns(:web_request).offer_id != nil
      assert assigns(:web_request).path.include?("featured_offer_shown")
    end

    should "not have more data" do
      @response = get(:featured, @params)
      assert_equal 0, assigns(:more_data_available)
    end

    should "have proper geoip data" do
      @response = get(:featured, @params)
      assert !assigns(:geoip_data).empty?
    end
  end

  context "when calling 'featured' with no offers available" do
    setup do
      @device = Factory(:device)
      @currency = Factory(:currency, :test_devices => @device.id)
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([])
      RailsCache.stubs(:get).returns(nil)
      @params = { :udid => 'stuff', :publisher_user_id => 'more_stuff', :currency_id => @currency.id, :app_id => @currency.app.id }
      @response = get(:index, @params)
    end

    should "return no offers" do
      assert assigns(:offer_list).empty?
      assert assigns(:web_request).offer_id.nil?
    end
  end

  context "in setup" do
    setup do
      @device = Factory(:device)
      @currency = Factory(:currency)
      @offer = Factory(:app).primary_offer
      controller.stubs(:get_ip_address).returns('208.90.212.38')
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])
      @params = { :udid => @device.id, :publisher_user_id => 'more_stuff', :currency_id => @currency.id, :app_id => @currency.app.id }
      @response = get(:index, @params)
    end

    should "assign web_request" do
      @response = get(:index, @params.merge(:exp => 10))
      web_request = assigns(:web_request)
      assert_equal web_request.viewed_at.to_s, assigns(:now).to_s
      assert_equal "10", web_request.exp
      assert_equal @request.headers["User-Agent"], web_request.user_agent
      assert_equal '208.90.212.38', web_request.ip_address
      assert_equal 'offerwall', web_request.source
      assert web_request.path.include? 'offers'

      @response = get(:index, @params.merge(:source => 'featured', :exp => 10, :type => '0'))
      web_request = assigns(:web_request)
      assert web_request.path.include? 'featured_offer_requested'
      assert_equal nil, web_request.exp
    end

    should "assign max_items" do
      assert_equal 25, assigns(:max_items)

      @response = get(:index, @params.merge(:max => 5))
      assert_equal 5, assigns(:max_items)
    end

    should "assign currency/currencies" do
      assert_equal @currency, assigns(:currency)

      @response = get(:index, @params.merge(:currency_selector => '1'))
      assert_equal @currency, assigns(:currency)
      assert assigns(:currencies)

      app = Factory(:app)
      @response = get(:index, @params.merge(:app_id => app.id))
      assert assigns(:currency).nil?

      @currency.id = @currency.app_id
      @currency.save
      @response = get(:index, @params.merge(:currency_id => nil))
      assert assigns(:currency)
    end

    should "assign start_index" do
      assert_equal @device.key, assigns(:device).key
      assert_equal 0, assigns(:start_index)

      @response = get(:index, @params.merge(:start => 2))
      assert_equal 2, assigns(:start_index)
    end

    should "set country from country_code" do
      @response = get(:index, @params.merge(:country_code => 'GB'))
      assert_equal 'GB', assigns(:geoip_data)[:country]
    end
  end
end
