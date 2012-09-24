require 'spec_helper'

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
        response.body.should include('missing parameters')
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
          :currency_id => @currency.id,
          :publisher_app_id => 'pub_app_id'
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
        @offer.should_receive(:queue_click_tracking_requests).with({
          :ip_address       => @controller.send(:ip_address),
          :udid             => 'stuff',
          :publisher_app_id => 'pub_app_id'}.with_indifferent_access).once

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
        :currency_id => @currency.id,
        :publisher_app_id => 'pub_app_id'
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
      @offer.should_receive(:queue_click_tracking_requests).with({
        :ip_address       => @controller.send(:ip_address),
        :udid             => 'app_stuff',
        :publisher_app_id => 'pub_app_id'}.with_indifferent_access).once

      get(:app, @params)
    end
  end
  describe '#coupon' do
    before :each do
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.tapjoy_enabled = true
      @offer.payment = 1
      @offer.user_enabled = true
      @offer.item_type = 'Coupon'
      params = {
        :udid => 'app_stuff',
        :offer_id => @offer.id,
        :viewed_at =>  (Time.zone.now - 1.hour).to_f,
        :currency_id => @currency.id,
        :publisher_app_id => 'pub_app_id'
      }
      @params = ObjectEncryptor.encrypt(params)
      @offer.stub(:destination_url).and_return("#{API_URL}/coupon_instructions/new?data=#{@params}")
      controller.stub(:verify_params).and_return(true)
      Offer.stub(:find_in_cache).and_return(@offer)
      Currency.stub(:find_in_cache).and_return(@currency)
    end

    it 'creates the correct click_key' do
      get(:coupon, :data => @params, :advertiser_app_id => 'even_more_app_stuff')
      assigns(:click_key).should == 'app_stuff.even_more_app_stuff'
    end

    it 'should redirect' do
      get(:coupon, :data => @params, :advertiser_app_id => 'even_more_app_stuff')
      response.should redirect_to("#{API_URL}/coupon_instructions/new?data=#{@params}")
    end

    it 'queues the offer\'s click_tracking_urls properly' do
      Click.any_instance.stub(:offer).and_return(@offer)
      @offer.should_receive(:queue_click_tracking_requests).with({
        :ip_address       => @controller.send(:ip_address),
        :udid             => 'app_stuff',
        :publisher_app_id => 'pub_app_id'}.with_indifferent_access).once

      get(:coupon, :data => @params, :advertiser_app_id => 'even_more_app_stuff')
    end
  end
  describe '#coupon' do
    context 'going through the coupon completion process' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.tapjoy_enabled = true
        @offer.payment = 1
        @offer.user_enabled = true
        @offer.item_type = 'Coupon'
        @app = FactoryGirl.create(:app)
        App.stub(:find_in_cache).and_return(@app)
        params = {
          :udid => 'app_stuff',
          :id => @offer.id,
          :offer_id => @offer.id,
          :viewed_at =>  (Time.zone.now - 1.hour).to_f,
          :currency_id => @currency.id,
          :publisher_app_id => @app.id,
          :app_id => @app.id
        }
        @params = ObjectEncryptor.encrypt(params)
        @offer.stub(:destination_url).and_return("#{API_URL}/coupon_instructions/new?data=#{@params}")
        controller.stub(:verify_params).and_return(true)
        Offer.stub(:find_in_cache).and_return(@offer)
        Currency.stub(:find_in_cache).and_return(@currency)
        Sqs.stub(:send_message).and_return(true)
        @offer.stub(:complete_action_url).and_return("#{API_URL}/coupons/complete?data=#{@params}")
        @coupon = FactoryGirl.create(:coupon)
        Coupon.stub(:find_in_cache).and_return(@coupon)
        visit coupon_click_path(:data => @params, :advertiser_app_id => 'even_more_app_stuff')
      end

      it 'renders coupon_instructions path' do
        response.should render_template('coupon_instructions/new')
      end
      it 'responds with 200' do
        response.should be_success
      end
      it 'has an an email address field' do
        page.has_field?(:email_address)
      end
      it 'has a submit button' do
        page.has_button?('Send Coupon')
      end
      it 'has coupon name' do
        page.has_content?(@coupon.name)
      end
      it 'has currency name' do
        page.has_content?(@currency.name)
      end
      context 'valid email' do
        before :each do
          fill_in 'email_address', :with => 'tapjoy@tapjoy.com'
          click_button('Send Coupon')
        end
        it 'goes to complete action' do
          response.should render_template('coupons/complete')
        end
        it 'responds with 200' do
          response.should be_success
        end
        it 'has success on the page' do
          page.has_content?('Success')
        end
        it 'has coupon\'s name' do
          page.has_content?(@coupon.name)
        end
      end
    end
  end
end
