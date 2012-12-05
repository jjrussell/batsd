require 'spec_helper'

describe ClickController do

  before :each do
    @currency = FactoryGirl.create(:currency)
    @currency.stub(:active_currency_sale).and_return(nil)
  end

  context "for all click types" do
    context 'with a udid' do
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
        @click = Click.new
        Click.stub(:new).and_return(@click)
        @device = FactoryGirl.create(:device)
        DeviceIdentifier.stub(:find_device_from_params).and_return(@device)
      end

      it "saves the click" do
        get(:generic, @params.merge(:advertiser_app_id => 'even_more_stuff'))
        @click.advertiser_app_id.should == 'even_more_stuff'
      end

      context "when store_name param is passed" do
        it "saves store_name param in click" do
          get(:generic, @params.merge(:advertiser_app_id => 'even_more_stuff', :store_name => 'some_store'))
          @click.store_name.should == 'some_store'
        end
      end

      context "when app is android and store_name param is not passed" do
        it "saves default store_name param in click" do
          get(:generic, @params.merge(:advertiser_app_id => 'even_more_stuff', :platform => 'android'))
          @click.store_name.should == 'google'
        end
      end
    end
    context 'with an advertising_id' do
      before :each do
        @offer = FactoryGirl.create(:generic_offer).primary_offer
        @offer.tapjoy_enabled = true
        @offer.payment = 1
        @offer.user_enabled = true
        @params = {
          :advertising_id => 'stuff',
          :offer_id => @offer.id,
          :viewed_at =>  (Time.zone.now - 1.hour).to_f,
          :currency_id => @currency.id,
          :publisher_app_id => 'pub_app_id'
        }
        controller.stub(:verify_params).and_return(true)
        Offer.stub(:find_in_cache).and_return(@offer)
        Currency.stub(:find_in_cache).and_return(@currency)
        @click = Click.new
        Click.stub(:new).and_return(@click)
        @device = FactoryGirl.create(:device)
        DeviceIdentifier.stub(:find_device_from_params).and_return(@device)
      end

      it "saves the click" do
        get(:generic, @params.merge(:advertiser_app_id => 'even_more_stuff'))
        @click.advertiser_app_id.should == 'even_more_stuff'
      end

      context "when store_name param is passed" do
        it "saves store_name param in click" do
          get(:generic, @params.merge(:advertiser_app_id => 'even_more_stuff', :store_name => 'some_store'))
          @click.store_name.should == 'some_store'
        end
      end

      context "when app is android and store_name param is not passed" do
        it "saves default store_name param in click" do
          get(:generic, @params.merge(:advertiser_app_id => 'even_more_stuff', :platform => 'android'))
          @click.store_name.should == 'google'
        end
      end
    end
  end

  describe "#generic" do
    context 'with udid' do
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
          @device = FactoryGirl.create(:device)
          DeviceIdentifier.stub(:find_device_from_params).and_return(@device)
        end

        it "requires gamer_id" do
          get(:generic, @params)
          response.status.should == 400
          response.body.should include('missing parameters')
        end

        context 'on success' do
          before(:each) do
            @params[:gamer_id] = UUIDTools::UUID.random_create.to_s
            @params[:advertiser_app_id] = TAPJOY_GAMES_INVITATION_OFFER_ID
            controller.stub(:verify_params).and_return(true)
            controller.stub(:recently_clicked?).and_return(false)
            Offer.stub(:find_in_cache).and_return(@offer)
            Currency.stub(:find_in_cache).and_return(@currency)
          end

          it "creates the correct click_key and redirects" do
            get(:generic, @params)
            assigns(:click_key).should_not be_nil
            assigns(:click_key).should == "#{@params[:gamer_id]}.#{TAPJOY_GAMES_INVITATION_OFFER_ID}"
            response.should be_redirect
          end

          it 'should generate a web request' do
            web_request = mock('web_request').as_null_object
            web_request.should_receive(:offer_is_paid=).with(false)
            web_request.should_receive(:offer_daily_budget=).with(0)
            web_request.should_receive(:offer_overall_budget=).with(0)
            WebRequest.should_receive(:new).and_return(web_request)

            get(:generic, @params)
          end
        end
      end

      context "for the TJM registration offer" do
        before :each do
          @offer = FactoryGirl.create(:generic_offer).primary_offer
          @device = FactoryGirl.create(:device)
          @offer.tapjoy_enabled = true
          @offer.payment = 1
          @offer.user_enabled = true
          @params = {
            :udid => 'stuff',
            :offer_id => @offer.id,
            :viewed_at =>  (Time.zone.now - 1.hour).to_f,
            :currency_id => @currency.id,
            :publisher_app_id => 'pub_app_id',
            :advertiser_app_id => TAPJOY_GAMES_REGISTRATION_OFFER_ID
          }
          controller.stub(:verify_params).and_return(true)
          @click = Click.new
          @device = FactoryGirl.create(:device)
          DeviceIdentifier.stub(:find_device_from_params).and_return(@device)
          Click.stub(:new).and_return(@click)
          Offer.stub(:find_in_cache).and_return(@offer)
          Currency.stub(:find_in_cache).and_return(@currency)
        end

        it "creates the correct click_key and redirects" do

          get(:generic, @params)
          assigns(:click_key).should_not be_nil
          assigns(:click_key).should == "#{@device.key}.#{TAPJOY_GAMES_REGISTRATION_OFFER_ID}"
          response.should be_redirect
        end

        context "when app is android and store_name param is not passed" do
          it "saves default store_name param in click" do
            get(:generic, @params.merge(:advertiser_app_id => 'even_more_stuff', :platform => 'android'))
            @click.store_name.should == 'google'
          end
        end
      end

      context "for regular generic offers" do
        before :each do
          @offer = FactoryGirl.create(:generic_offer).primary_offer
          @device = FactoryGirl.create(:device)
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
          Device.stub(:find).and_return(@device)
        end

        it "creates the correct click_key and redirects" do
          get(:generic, @params.merge(:advertiser_app_id => 'even_more_stuff'))
          assigns(:click_key).should_not be_nil
          assigns(:click_key).should == Digest::MD5.hexdigest("#{@device.key}.even_more_stuff")
          response.should be_redirect
        end

        it "queues the offer's click_tracking_urls properly" do
          Click.any_instance.stub(:offer).and_return(@offer)
          @params.merge!(:advertiser_app_id => 'testing click_tracking')
          @offer.should_receive(:queue_click_tracking_requests).with({
            :ip_address       => @controller.send(:ip_address),
            :tapjoy_device_id => @device.key,
            :publisher_app_id => 'pub_app_id'}.with_indifferent_access).once

          get(:generic, @params)
        end
      end
    end
    context 'with advertising_id' do
      context "for the TJM invitation offer" do
        before :each do
          @offer = FactoryGirl.create(:generic_offer).primary_offer
          @offer.tapjoy_enabled = true
          @offer.payment = 1
          @offer.user_enabled = true
          @device = FactoryGirl.create(:device)
          @params = {
            :advertising_id => 'stuff',
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
          DeviceIdentifier.stub(:find_device_from_params).and_return(@device)
          get(:generic, @params)
          assigns(:click_key).should_not be_nil
          assigns(:click_key).should == "#{@params[:gamer_id]}.#{TAPJOY_GAMES_INVITATION_OFFER_ID}"
          response.should be_redirect
        end
      end

      context "for the TJM registration offer" do
        before :each do
          @offer = FactoryGirl.create(:generic_offer).primary_offer
          @device = FactoryGirl.create(:device)
          @offer.tapjoy_enabled = true
          @offer.payment = 1
          @offer.user_enabled = true
          @params = {
            :advertising_id => 'stuff',
            :offer_id => @offer.id,
            :viewed_at =>  (Time.zone.now - 1.hour).to_f,
            :currency_id => @currency.id,
            :advertiser_app_id => TAPJOY_GAMES_REGISTRATION_OFFER_ID
          }
          controller.stub(:verify_params).and_return(true)
          Offer.stub(:find_in_cache).and_return(@offer)
          Currency.stub(:find_in_cache).and_return(@currency)
          DeviceIdentifier.stub(:find_device_from_params).and_return(@device)
        end

        it "creates the correct click_key and redirects" do
          get(:generic, @params)
          assigns(:click_key).should_not be_nil
          assigns(:click_key).should == "#{@device.key}.#{TAPJOY_GAMES_REGISTRATION_OFFER_ID}"
          response.should be_redirect
        end
      end

      context "for regular generic offers" do
        before :each do
          @offer = FactoryGirl.create(:generic_offer).primary_offer
          @device = FactoryGirl.create(:device)
          @offer.tapjoy_enabled = true
          @offer.payment = 1
          @offer.user_enabled = true
          @params = {
            :advertising_id => 'stuff',
            :offer_id => @offer.id,
            :viewed_at =>  (Time.zone.now - 1.hour).to_f,
            :currency_id => @currency.id,
            :publisher_app_id => 'pub_app_id'
          }
          controller.stub(:verify_params).and_return(true)
          Offer.stub(:find_in_cache).and_return(@offer)
          Currency.stub(:find_in_cache).and_return(@currency)
          DeviceIdentifier.stub(:find_device_from_params).and_return(@device)
        end

        it "creates the correct click_key and redirects" do
          get(:generic, @params.merge(:advertiser_app_id => 'even_more_stuff'))
          assigns(:click_key).should_not be_nil
          assigns(:click_key).should == Digest::MD5.hexdigest("#{@device.key}.even_more_stuff")
          response.should be_redirect
        end

        it "queues the offer's click_tracking_urls properly" do
          Click.any_instance.stub(:offer).and_return(@offer)
          @params.merge!(:advertiser_app_id => 'testing click_tracking')
          @offer.should_receive(:queue_click_tracking_requests).with({
            :ip_address       => @controller.send(:ip_address),
            :tapjoy_device_id => @device.key,
            :publisher_app_id => 'pub_app_id'}.with_indifferent_access).once

          get(:generic, @params)
        end
      end
    end
  end

  describe '#deeplink' do
    before :each do
      @currency = FactoryGirl.create(:currency)
      @currency.stub(:active_currency_sale).and_return(nil)
      @deeplink_offer = @currency.deeplink_offer
      @offer= @deeplink_offer.primary_offer
      @device = FactoryGirl.create(:device)
      Device.stub(:find).and_return(@device)
      Offer.stub(:find_in_cache).and_return(@offer)
      Currency.stub(:find_in_cache).and_return(@currency)
      @offer.stub(:format_as_click_key).and_return('click_key')
      params={ :udid => @device.key, :offer_id => @offer.id,
               :publisher_app_id => @currency.app_id,
               :currency_id => @currency.id,
               :viewed_at => (Time.zone.now - 1.hour).to_i }
      @data={ :data => ObjectEncryptor.encrypt(params) }

      url_params = { :udid => @device.key,
                     :id => @currency.id,
                     :click_key => 'click_key',
                     :tapjoy_device_id => @device.key
      }
      @params = ObjectEncryptor.encrypt(url_params)
      @expected_redirect = "#{WEBSITE_URL}/earn?data=#{@params}"
      @offer.stub(:destination_url).and_return(@expected_redirect)

    end
    it 'redirects to the correct earn page', :click do
      get(:deeplink, @data)
      response.should be_redirect
      response.should redirect_to(@expected_redirect)
    end

  end
  describe "#app" do
    before :each do
      @offer = FactoryGirl.create(:app).primary_offer
      @device = FactoryGirl.create(:device)
      @offer.tapjoy_enabled = true
      @offer.payment = 1
      @offer.user_enabled = true
      @params = {
        :udid => 'app_stuff',
        :offer_id => @offer.id,
        :viewed_at =>  (Time.zone.now - 1.hour).to_f,
        :currency_id => @currency.id,
        :publisher_app_id => 'pub_app_id',
        :mac_address => 'device_mac_address'
      }
      controller.stub(:verify_params).and_return(true)
      Offer.stub(:find_in_cache).and_return(@offer)
      Currency.stub(:find_in_cache).and_return(@currency)
      Device.stub(:find).and_return(@device)
    end

    it "creates the correct click_key and redirects" do
      get(:app, @params.merge(:advertiser_app_id => 'even_more_app_stuff'))
      assigns(:click_key).should_not be_nil
      assigns(:click_key).should == "#{@device.key}.even_more_app_stuff"
      response.should be_redirect
    end

    it "queues the offer's click_tracking_urls properly" do
      Click.any_instance.stub(:offer).and_return(@offer)
      @params.merge!(:advertiser_app_id => 'testing click_tracking')
      @offer.should_receive(:queue_click_tracking_requests).with({
        :ip_address       => @controller.send(:ip_address),
        :tapjoy_device_id => @device.key,
        :publisher_app_id => 'pub_app_id'}.with_indifferent_access).once

      get(:app, @params)
    end
  end

  describe '#coupon' do
    before :each do
      @offer = FactoryGirl.create(:app).primary_offer
      @device = FactoryGirl.create(:device)
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
      Device.stub(:find).and_return(@device)
    end

    it 'creates the correct click_key' do
      get(:coupon, :data => @params, :advertiser_app_id => 'even_more_app_stuff')
      assigns(:click_key).should == "#{@device.key}.even_more_app_stuff"
    end

    it 'should redirect' do
      get(:coupon, :data => @params, :advertiser_app_id => 'even_more_app_stuff')
      response.should redirect_to("#{API_URL}/coupon_instructions/new?data=#{@params}")
    end

    it 'queues the offer\'s click_tracking_urls properly' do
      Click.any_instance.stub(:offer).and_return(@offer)
      @offer.should_receive(:queue_click_tracking_requests).with({
        :ip_address       => @controller.send(:ip_address),
        :tapjoy_device_id => @device.key,
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
        @device = FactoryGirl.create(:device)
        Device.stub(:find).and_return(@device)
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
    end
  end

  context "pay_per_click" do
    describe "#handle_pay_per_click" do
      before :each do
        @now = Time.zone.parse("2012-01-01 00:00:00")
        Timecop.freeze(@now)

        @device = FactoryGirl.create(:device)
        @device.stub(:set_last_run_time!)

        @offer = FactoryGirl.create(:app).primary_offer
        @offer.tapjoy_enabled = true

        @params = {
          :udid => @device.id,
          :offer_id => @offer.id,
          :viewed_at =>  (@now - 1.hour).to_f,
          :currency_id => @currency.id,
          :publisher_app_id => 'pub_app_id',
          :mac_address => 'device_mac_address'
        }

        Offer.stub(:find_in_cache).and_return(@offer)

        @controller = ClickController.new
        @controller.params = @params
        @controller.stub(:verify_params).and_return(true)
        @controller.stub(:find_or_create_device).and_return(@device)
        @controller.send(:setup)

        @message = { :click_key => @controller.send(:click_key), :install_timestamp => @now.to_f.to_s }.to_json
      end

      after :each do
        Timecop.return
      end

      it "should not queue conversion tracking if offer's pay_per_click is not ppc_on_offerwall", :ppc do
        @offer.pay_per_click = Offer::PAY_PER_CLICK_TYPES[:ppc_on_instruction]
        Sqs.should_not_receive(:send_message).with(QueueNames::CONVERSION_TRACKING, @message)
        @controller.send(:handle_pay_per_click)
      end

      it "should queue conversion tracking if offer's pay_per_click is ppc_on_offerwall", :ppc do
        @offer.pay_per_click = Offer::PAY_PER_CLICK_TYPES[:ppc_on_offerwall]
        Sqs.should_receive(:send_message).with(QueueNames::CONVERSION_TRACKING, @message)
        @controller.send(:handle_pay_per_click)
      end
    end
  end
end
