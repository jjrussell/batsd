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
      assert_template "get_offers/webpage_redesign"
      assert_equal "layouts/iphone_redesign", @response.layout

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

    should "assign instance variables" do
      @response = get(:index, @params.merge(:exp => 10))
      web_request = assigns(:web_request)
      assert_equal web_request.viewed_at.to_s, assigns(:now).to_s
      assert_equal "10", web_request.exp
      assert_equal @request.headers["User-Agent"], web_request.user_agent
      assert_equal '208.90.212.38', web_request.ip_address
      assert_equal 'offerwall', web_request.source
      assert_equal @device.key, assigns(:device).key
      assert_equal 25, assigns(:max_items)
      assert_equal 0, assigns(:start_index)

      assert web_request.path.include? 'offers'
      assert_equal @currency, assigns(:currency)

      @response = get(:index, @params.merge(:source => 'featured', :exp => 10, :type => '0'))
      web_request = assigns(:web_request)
      assert web_request.path.include? 'featured_offer_requested'
      assert_equal nil, web_request.exp

      @response = get(:index, @params.merge(:currency_selector => '1'))
      assert_equal @currency, assigns(:currency)
      assert assigns(:currencies)

      @response = get(:index, @params.merge(:max => 5))
      assert_equal 5, assigns(:max_items)

      @response = get(:index, @params.merge(:start => 2))
      assert_equal 2, assigns(:start_index)

      @response = get(:index, @params.merge(:country_code => 'GB'))
      assert_equal 'GB', assigns(:geoip_data)[:country]

      app = Factory(:app)
      @response = get(:index, @params.merge(:app_id => app.id))
      assert assigns(:currency).nil?

      @currency.id = @currency.app_id
      @currency.save
      @response = get(:index, @params.merge(:currency_id => nil))
      assert assigns(:currency)
    end
  end
end
