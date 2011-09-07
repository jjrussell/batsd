require 'test_helper'

class GetOffersControllerTest < ActionController::TestCase
  context "when calling 'index'" do
    setup do
      @currency = Factory(:currency)
      @offer = Factory(:app).primary_offer
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])
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

    should "have proper geoip date" do
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
end
