require 'spec_helper'

describe SupportRequest do
  before :each do
    fake_the_web
    @support_request = SupportRequest.new

    @app = Factory(:app)
    @offer = @app.primary_offer
    @currency = Factory(:currency, :app => @app)
    @device = Factory(:device)
    publisher_app = Factory(:app)
    @click = Factory(:click,  :udid                 => @device.key,
                              :currency_id          => @currency.id,
                              :offer_id             => @offer.id,
                              :publisher_app_id     => publisher_app.id,
                              :publisher_partner_id => publisher_app.partner_id,
                              :publisher_user_id    => "click_test_user" )

    @user_agent = "rspec"
    @params =  {  :language_code        => "en",
                  :udid                 => "test_udid",
                  :publisher_app_id     => "test_publisher_app",
                  :publisher_partner_id => "test_publisher_partner",
                  :publisher_user_id    => "test_publisher_user",
                  :currency_id          => "test_currency",
                  :app_id               => "test_app",
                  :offer_id             => "test_offer",
                  :device_type          => "android",
                  :description          => "I'm needy and have lots of problems",
                  :email_address        => "test@tapjoy.com",
                  :click_id             => "test_click" }
  end

  describe '#fill_from_params' do
    context 'when an offer is provided' do
      it "stores the offer's id" do
        @support_request.fill_from_params(@params, @app, @currency, @offer, @user_agent)
        @support_request.offer_id.should == @offer.id
      end

      context 'with a click association' do
        before :each do
          @support_request.stubs(:get_last_click).returns(@click)
        end

        it "stores the click's id" do
          @support_request.fill_from_params(@params, @app, @currency, @offer, @user_agent)
          @support_request.click_id.should == @click.id
        end
      end

      context 'without a click association' do
        before :each do
          @support_request.stubs(:get_last_click).returns(nil)
        end

        it "leaves click_id blank" do
          @support_request.fill_from_params(@params, @app, @currency, @offer, @user_agent)
          @support_request.click_id.should be_blank
        end
      end
    end

    context 'when no offer is provided' do
      it "leaves offer_id blank" do
        @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
        @support_request.offer_id.should be_blank
      end

      it "leaves click_id blank" do
        @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
        @support_request.click_id.should be_blank
      end
    end

    it "stores the description message from the params array" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.description.should == @params[:description]
    end

    it "stores the UDID from the params array" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.udid.should == @params[:udid]
    end

    it "stores the email address from the params array" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.email_address.should == @params[:email_address]
    end

    it "stores the publisher's app id from the params array" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.publisher_app_id.should == @params[:publisher_app_id]
    end

    it "stores the publisher's partner id from the params array" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.publisher_partner_id.should == @params[:publisher_partner_id]
    end

    it "stores the publisher's user id from the params array" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.publisher_user_id.should == @params[:publisher_user_id]
    end

    it "stores device type from params array" do
      @support_request.fill_from_params(@params, @app, @currency, @offer, @user_agent)
      @support_request.device_type.should == @params[:device_type]
    end

    it "stores the user_agent from the user_agent argument" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.user_agent.should == @user_agent
    end

    it "stores the language code from the params array" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.language_code.should == @params[:language_code]
    end

    it "stores the app's id from the app model" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.app_id.should == @app.id
    end

    it "stores the currency's id from the currency model" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.currency_id.should == @currency.id
    end

    it "leaves gamer_id blank" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.gamer_id.should be_blank
    end
  end

  describe '#fill_from_click' do
    before :each do
      @gamer = Factory(:gamer)
      @gamer_device = GamerDevice.new(:device => @device)
      @gamer_device.device_type = "android"
      @gamer.devices << @gamer_device
    end

    context 'when a click is provided' do
      it "stores the publisher's app id from the click model" do
        @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
        @support_request.publisher_app_id.should == @click.publisher_app_id
      end

      it "stores the publisher's partner id from the click model" do
        @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
        @support_request.publisher_partner_id.should == @click.publisher_partner_id
      end

      it "stores the publisher user id from the click model" do
        @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
        @support_request.publisher_user_id.should == @click.publisher_user_id
      end

      it "stores the app's id from the click model" do
        @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
        @support_request.app_id.should == @click.offer.item_id
      end

      it "stores the currency's id from the click model" do
        @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
        @support_request.currency_id.should == @click.currency_id
      end

      it "stores the offer's id from the click model" do
        @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
        @support_request.offer_id.should == @click.offer_id
      end

      it "stores the click model's id" do
        @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
        @support_request.click_id.should == @click.id
      end
    end

    context 'when no click is provided' do
      it "stores the publisher's app id from the params array" do
        @support_request.fill_from_click(nil, @params, @gamer_device, @gamer, @user_agent)
        @support_request.publisher_app_id.should == @params[:publisher_app_id]
      end

      it "stores the publisher's partner id from the params array" do
        @support_request.fill_from_click(nil, @params, @gamer_device, @gamer, @user_agent)
        @support_request.publisher_partner_id.should == @params[:publisher_partner_id]
      end

      it "stores the publisher user id from the params array" do
        @support_request.fill_from_click(nil, @params, @gamer_device, @gamer, @user_agent)
        @support_request.publisher_user_id.should == @params[:publisher_user_id]
      end

      it "stores the app's id from the params array" do
        @support_request.fill_from_click(nil, @params, @gamer_device, @gamer, @user_agent)
        @support_request.app_id.should == @params[:app_id]
      end

      it "stores the currency's id from the params array" do
        @support_request.fill_from_click(nil, @params, @gamer_device, @gamer, @user_agent)
        @support_request.currency_id.should == @params[:currency_id]
      end

      it "leaves offer_id blank" do
        @support_request.fill_from_click(nil, @params, @gamer_device, @gamer, @user_agent)
        @support_request.offer_id.should be_blank
      end

      it "leaves click_id blank" do
        @support_request.fill_from_click(nil, @params, @gamer_device, @gamer, @user_agent)
        @support_request.click_id.should be_blank
      end
    end

    it "stores the description message from the params array" do
      @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
      @support_request.description.should == @params[:description]
    end

    it "stores UDID from device model" do
      @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
      @support_request.udid.should == @gamer_device.device_id
    end

    it "stores the email address from the gamer model" do
      @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
      @support_request.email_address.should == @gamer.email
    end

    it "store device type from device model" do
      @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
      @support_request.device_type.should == @gamer_device.device_type
    end

    it "stores the user_agent from the user_agent argument" do
      @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
      @support_request.user_agent.should == @user_agent
    end

    it "stores the language code from the params array" do
      @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
      @support_request.language_code.should == @params[:language_code]
    end

    it "stores the gamer's id from the gamer model" do
      @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
      @support_request.language_code.should == @params[:language_code]
    end
  end
end
