require 'spec_helper'

describe SupportRequest do
  before :each do
    @support_request = SupportRequest.new

    @app = FactoryGirl.create(:app)
    @offer = @app.primary_offer
    @currency = FactoryGirl.create(:currency, :app => @app)
    @device = FactoryGirl.create(:device, :udid => 'device_udid')
    Device.stub(:find).and_return(@device)
    publisher_app = FactoryGirl.create(:app)
    @click = FactoryGirl.create(:click,  :udid        => @device.udid,
                                :currency_id          => @currency.id,
                                :offer_id             => @offer.id,
                                :publisher_app_id     => publisher_app.id,
                                :publisher_partner_id => publisher_app.partner_id,
                                :publisher_user_id    => "click_test_user",
                                :source               => "offerwall" )
    @user_agent = "rspec"
    @params =  {  :language_code        => "en",
                  :udid                 => "test_udid",
                  :mac_address          => "test_mac",
                  :tapjoy_device_id     => "tapjoy_device_id_test",
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

      it "stores whether currency is managed or not", :managed_currency_from_params do
        @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
        @support_request.managed_currency.should == @currency.tapjoy_managed?
      end

      it "stores the offer's payment" do
        @support_request.fill_from_params(@params, @app, @currency, @offer, @user_agent)
        @support_request.offer_value.should == @offer.payment
      end

      context 'with a click association' do
        before :each do
          @support_request.stub(:get_last_click).and_return(@click)
        end

        it "stores the click's id" do
          @support_request.fill_from_params(@params, @app, @currency, @offer, @user_agent)
          @support_request.click_id.should == @click.id
        end
      end

      context 'without a click association' do
        before :each do
          @support_request.stub(:get_last_click).and_return(nil)
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

      it "leaves offer_value blank" do
        @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
        @support_request.offer_value.should be_blank
      end
    end

    it "stores the description message from the params array" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.description.should == @params[:description]
    end

    it "stores the device_id from the params array" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.tapjoy_device_id.should == @params[:tapjoy_device_id]
    end

    it "stores the UDID from the params array" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.udid.should == @params[:udid]
    end

    it "stores the mac_address from the params array" do
      @support_request.fill_from_params(@params, @app, @currently, nil, @user_agent)
      @support_request.mac_address.should == @params[:mac_address]
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

    it "leaves click_source blank" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.click_source.should be_blank
    end

    it "stores lives_at from a constant" do
      @support_request.fill_from_params(@params, @app, @currency, nil, @user_agent)
      @support_request.lives_in.should == 'offerwall'
    end
  end

  describe '#get_last_click' do
    it 'should perform the proper SimpleDB query' do
      device_id, offer = 'test device_id', FactoryGirl.create(:app).primary_offer
      conditions = ["tapjoy_device_id = ? or udid = ? and advertiser_app_id = ? and manually_resolved_at is null", device_id, device_id, offer.item_id]

      Click.should_receive(:select_all).with({ :conditions => conditions }).once.and_return([])
      @support_request.get_last_click(device_id, offer)
    end
  end
end
