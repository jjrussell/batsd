require 'spec/spec_helper'

describe ClickController do

  before :each do
    fake_the_web
    @currency = Factory(:currency)
  end

  describe "#generic" do
    context "for the TJM invitation offer" do
      before :each do
        @offer = Factory(:generic_offer).primary_offer
        @offer.tapjoy_enabled = true
        @offer.payment = 1
        @offer.user_enabled = true
        @params = {
          :udid => 'stuff',
          :offer_id => @offer.id,
          :viewed_at =>  (Time.zone.now - 1.hour).to_f,
          :currency_id => @currency.id,
          :advertiser_app_id => TAPJOY_GAMES_INVITATION_OFFER_ID
        }
      end

      it "requires gamer_id" do
        get(:generic, @params)
        response.status.should == 400
        response.body.should == 'missing required params'
      end

      it "creates the correct click_key and redirects" do
        @params[:gamer_id] = UUIDTools::UUID.random_create.to_s
        controller.stubs(:verify_params).returns(true)
        controller.stubs(:recently_clicked?).returns(false)
        Offer.stubs(:find_in_cache).returns(@offer)
        Currency.stubs(:find_in_cache).returns(@currency)
        get(:generic, @params)
        assigns(:click_key).should_not be_nil
        assigns(:click_key).should == "#{@params[:gamer_id]}.#{TAPJOY_GAMES_INVITATION_OFFER_ID}"
        response.should be_redirect
      end
    end

    context "for the TJM registration offer" do
      before :each do
        @offer = Factory(:generic_offer).primary_offer
        @offer.tapjoy_enabled = true
        @offer.payment = 1
        @offer.user_enabled = true
        @params = {
          :udid => 'stuff',
          :offer_id => @offer.id,
          :viewed_at =>  (Time.zone.now - 1.hour).to_f,
          :currency_id => @currency.id,
          :advertiser_app_id => TAPJOY_GAMES_REGISTRATION_OFFER_ID
        }
      end

      it "creates the correct click_key and redirects" do
        controller.stubs(:verify_params).returns(true)
        Offer.stubs(:find_in_cache).returns(@offer)
        Currency.stubs(:find_in_cache).returns(@currency)
        get(:generic, @params)
        assigns(:click_key).should_not be_nil
        assigns(:click_key).should == "stuff.#{TAPJOY_GAMES_REGISTRATION_OFFER_ID}"
        response.should be_redirect
      end
    end

    context "for regular generic offers" do
      before :each do
        @offer = Factory(:generic_offer).primary_offer
        @offer.tapjoy_enabled = true
        @offer.payment = 1
        @offer.user_enabled = true
        @params = {
          :udid => 'stuff',
          :offer_id => @offer.id,
          :viewed_at =>  (Time.zone.now - 1.hour).to_f,
          :currency_id => @currency.id,
          :advertiser_app_id => 'even_more_stuff'
        }
      end

      it "creates the correct click_key and redirects" do
        controller.stubs(:verify_params).returns(true)
        Offer.stubs(:find_in_cache).returns(@offer)
        Currency.stubs(:find_in_cache).returns(@currency)
        get(:generic, @params)
        assigns(:click_key).should_not be_nil
        assigns(:click_key).should == Digest::MD5.hexdigest('stuff.even_more_stuff')
        response.should be_redirect
      end
    end
  end

  describe "#app" do
    before :each do
      @offer = Factory(:app).primary_offer
      @offer.tapjoy_enabled = true
      @offer.payment = 1
      @offer.user_enabled = true
      @params = {
        :udid => 'app_stuff',
        :offer_id => @offer.id,
        :viewed_at =>  (Time.zone.now - 1.hour).to_f,
        :currency_id => @currency.id,
        :advertiser_app_id => 'even_more_app_stuff'
      }
    end

    it "creates the correct click_key and redirects" do
      controller.stubs(:verify_params).returns(true)
      Offer.stubs(:find_in_cache).returns(@offer)
      Currency.stubs(:find_in_cache).returns(@currency)
      get(:app, @params)
      assigns(:click_key).should_not be_nil
      assigns(:click_key).should == 'app_stuff.even_more_app_stuff'
      response.should be_redirect
    end
  end
end
