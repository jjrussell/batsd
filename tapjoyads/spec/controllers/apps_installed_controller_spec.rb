require 'spec_helper'

describe AppsInstalledController do
  render_views

  context '#index' do
    before :each do
      app = FactoryGirl.create(:app)
      app1 = FactoryGirl.create(:app)
      app2 = FactoryGirl.create(:app)
      app3 = FactoryGirl.create(:app)

      @offer1 = app1.primary_offer
      @offer1.third_party_data = 'package.name.1'
      @offer1.save
      @offer2 = app2.primary_offer
      @offer2.third_party_data = 'package.name.2'
      @offer2.save
      @offer3 = app3.primary_offer
      @offer3.third_party_data = 'package.name.3'
      @offer3.save

      @device = FactoryGirl.create(:device)
      @device.sdkless_clicks = { @offer1.third_party_data => { 'click_time' => (Time.zone.now - 1.hour).to_i, 'item_id' => @offer1.id },
                                 @offer2.third_party_data => { 'click_time' => (Time.zone.now - 2.hours).to_i, 'item_id' => @offer2.id },
                                 @offer3.third_party_data => { 'click_time' => (Time.zone.now - 3.hours).to_i, 'item_id' => @offer3.id }}

      @params = { :app_id           => app.id,
                  :udid             => @device.key,
                  :sdk_type         => 'offers',
                  :library_version  => SDKLESS_MIN_LIBRARY_VERSION,
                  :package_names    => "#{@offer1.third_party_data},#{@offer2.third_party_data}",
                  :verifier         => 'verifier',
                }

      controller.stub(:generate_verifier).and_return('verifier')
      Device.stub(:new).and_return(@device)
    end

    context 'without required parameter values' do
      it "returns an error when udid is omitted" do
        @params.delete(:udid)
        get(:index, @params)
        response.body.should include('missing parameters')
      end

      it "returns an error when app_id is omitted" do
        @params.delete(:app_id)
        get(:index, @params)
        response.body.should include('missing parameters')
      end

      it "returns an error when library_version is omitted" do
        @params.delete(:library_version)
        get(:index, @params)
        response.body.should include('missing parameters')
      end

      it "returns an error when sdk_type is omitted" do
        @params.delete(:sdk_type)
        get(:index, @params)
        response.body.should include('missing parameters')
      end

      it "returns an error when verifier is omitted" do
        @params.delete(:verifier)
        get(:index, @params)
        response.body.should include('missing parameters')
      end

      it "returns an error when package_names is omitted" do
        @params.delete(:package_names)
        get(:index, @params)
        response.body.should include('missing parameters')
      end

      it "returns an error when verifier is invalid" do
        @params[:verifier] = 'invalid'
        get(:index, @params)
        response.body.should include('invalid verifier')
      end

      it "returns an error if API does not support SDK-less clicks" do
        @params[:sdk_type] = 'connect'
        get(:index, @params)
        response.body.should include('sdkless not supported')
      end
    end

    context 'with required parameters' do
      it "returns a 200 OK when sdk_type is offers" do
        get(:index, @params)
        response.response_code.should == 200
      end

      it "returns a 200 OK when sdk_type is virtual_goods" do
        @params[:sdk_type] = 'virtual_goods'
        get(:index, @params)
        response.response_code.should == 200
      end

      it "creates click models only for sdkless clicks stored on device model" do
        mock_click1 = mock()
        mock_click1.should_receive(:key).and_return("#{@device.key}.#{@offer1.id}")
        mock_click2 = mock()
        mock_click2.should_receive(:key).and_return("#{@device.key}.#{@offer2.id}")

        Click.should_receive(:new).with(:key => "#{@device.key}.#{@offer1.id}").and_return(mock_click1)
        Click.should_receive(:new).with(:key => "#{@device.key}.#{@offer2.id}").and_return(mock_click2)
        Click.should_receive(:new).with(:key => "#{@device.key}.#{@offer3.id}").never
        get(:index, @params)
      end

      it "adds sdkless clicks to SQS conversion queue" do
        Sqs.should_receive(:send_message).twice
        get(:index, @params)
      end

      it "removes queued sdkless clicks from device model" do
        get(:index, @params)
        @device.sdkless_clicks.should_not include(@offer1.third_party_data)
        @device.sdkless_clicks.should_not include(@offer2.third_party_data)
      end

      it "doesn't remove sdkless clicks that weren't in apps_installed params" do
        get(:index, @params)
        @device.sdkless_clicks.should include(@offer3.third_party_data)
      end

      it "creates a web request for this apps_installed call" do
        get(:index, @params)
        web_request = assigns(:web_request)
        assigns(:now).to_s.should == web_request.viewed_at.to_s
        web_request.user_agent.should == @request.headers["User-Agent"]
        web_request.path.should include('apps_installed')
      end
    end
  end
end
