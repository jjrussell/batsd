require 'spec/spec_helper'

describe ClickController do

  before :each do
    @currency = FactoryGirl.create(:currency)
  end

  describe "#generic" do
    context "for the TJM invitation offer" do
      before :each do
        @offer = FactoryGirl.create(:generic_offer).primary_offer
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
        controller.stub(:verify_params).and_return(true)
        controller.stub(:recently_clicked?).and_return(false)
        Offer.stub(:find_in_cache).and_return(@offer)
        Currency.stub(:find_in_cache).and_return(@currency)
        get(:generic, @params)
        assigns(:click_key).should_not be_nil
        assigns(:click_key).should == "#{@params[:gamer_id]}.#{TAPJOY_GAMES_INVITATION_OFFER_ID}"
        response.should be_redirect
      end
    end

    context "for the TJM registration offer" do
      before :each do
        @offer = FactoryGirl.create(:generic_offer).primary_offer
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
        controller.stub(:verify_params).and_return(true)
        Offer.stub(:find_in_cache).and_return(@offer)
        Currency.stub(:find_in_cache).and_return(@currency)
        get(:generic, @params)
        assigns(:click_key).should_not be_nil
        assigns(:click_key).should == "stuff.#{TAPJOY_GAMES_REGISTRATION_OFFER_ID}"
        response.should be_redirect
      end
    end

    context "for regular generic offers" do
      before :each do
        @offer = FactoryGirl.create(:generic_offer).primary_offer
        @offer.tapjoy_enabled = true
        @offer.payment = 1
        @offer.user_enabled = true
        @params = {
          :udid => 'stuff',
          :offer_id => @offer.id,
          :viewed_at =>  (Time.zone.now - 1.hour).to_f,
          :currency_id => @currency.id
        }
        controller.stub(:verify_params).and_return(true)
        Offer.stub(:find_in_cache).and_return(@offer)
        Currency.stub(:find_in_cache).and_return(@currency)
      end

      it "creates the correct click_key and redirects" do
        get(:generic, @params.merge(:advertiser_app_id => 'even_more_stuff'))
        assigns(:click_key).should_not be_nil
        assigns(:click_key).should == Digest::MD5.hexdigest('stuff.even_more_stuff')
        response.should be_redirect
      end

      it "queues the offer's click_tracking_urls properly" do
        Click.any_instance.stub(:offer).and_return(@offer)
        @params.merge!(:advertiser_app_id => 'testing click_tracking')
        @offer.should_receive(:queue_click_tracking_requests).once

        get(:generic, @params)
      end
    end
  end

  describe '#deeplink' do
    before :each do
      @currency = FactoryGirl.create(:currency)
      @deeplink_offer = @currency.deeplink_offer
      @udid = '0000222200002229'
      @offer= @deeplink_offer.primary_offer
    end
    it 'redirects to the correct earn page' do
      params={ :udid => @udid, :offer_id => @offer.id,
               :publisher_app_id => @currency.app_id,
               :currency_id => @currency.id,
               :viewed_at => (Time.zone.now - 1.hour).to_i }
      data={ :data => ObjectEncryptor.encrypt(params) }
      get(:deeplink, data)
      response.should be_redirect
      url_params = { :udid => @udid,
                     :publisher_app_id => @currency.app_id,
                     :currency => @currency,
                     :click_key => @offer.format_as_click_key(params)
      }
      response.should redirect_to(@offer.destination_url(url_params))
    end

  end
  describe "#app" do
    before :each do
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.tapjoy_enabled = true
      @offer.payment = 1
      @offer.user_enabled = true
      @params = {
        :udid => 'app_stuff',
        :offer_id => @offer.id,
        :viewed_at =>  (Time.zone.now - 1.hour).to_f,
        :currency_id => @currency.id
      }
      controller.stub(:verify_params).and_return(true)
      Offer.stub(:find_in_cache).and_return(@offer)
      Currency.stub(:find_in_cache).and_return(@currency)
    end

    it "creates the correct click_key and redirects" do
      get(:app, @params.merge(:advertiser_app_id => 'even_more_app_stuff'))
      assigns(:click_key).should_not be_nil
      assigns(:click_key).should == 'app_stuff.even_more_app_stuff'
      response.should be_redirect
    end

    it "queues the offer's click_tracking_urls properly" do
      Click.any_instance.stub(:offer).and_return(@offer)
      @params.merge!(:advertiser_app_id => 'testing click_tracking')
      @offer.should_receive(:queue_click_tracking_requests).once

      get(:app, @params)
    end
  end
end
