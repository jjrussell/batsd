require 'spec_helper'

describe SupportRequest do
  before :each do
    fake_the_web
    @support_request = SupportRequest.new

    @device = Factory(:device)
    @app = Factory(:app)
    @offer = @app.primary_offer
    @currency = Factory(:currency, :app => @app)
    @click = Factory(:click, :udid => @device.key, :currency_id => @currency.id, :offer_id => @offer.id)

    # Build params array and user_agent
    @user_agent = "rspec"
    @params =  {  :language_code      => "",
                  :udid               => "test_udid",
                  :publisher_user_id  => "test_user",
                  :currency_id        => "test_currency",
                  :app_id             => "test_app",
                  :offer_id           => "test_offer",
                  :device_type        => "android",
                  :description        => "I'm needy and have lots of problems",
                  :email_address      => "test@tapjoy.com",
                }
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

    it "store device type from params array" do
      @support_request.fill_from_params(@params, @app, @currency, @offer, @user_agent)
      @support_request.device_type.should == @params[:device_type]
    end
  end

  describe '#fill_from_click' do
    before :each do
      @gamer = Factory(:gamer)
      @gamer_device = GamerDevice.new(:device => @device)
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

      it "stores the offer's id from the params array" do
        @support_request.fill_from_click(nil, @params, @gamer_device, @gamer, @user_agent)
        @support_request.offer_id.should == @params[:offer_id]
      end

      it "stores the click's id from the params array" do
        @support_request.fill_from_click(nil, @params, @gamer_device, @gamer, @user_agent)
        @support_request.click_id.should == @params[:click_id]
      end
    end

    it "store device type from device model" do
      @support_request.fill_from_click(@click, @params, @gamer_device, @gamer, @user_agent)
      @support_request.device_type.should == @gamer_device.device_type
    end
  end
end
