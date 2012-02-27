require 'spec/spec_helper'

describe AppsInstalledController do
  integrate_views

  before :each do
    fake_the_web
    Sqs.stubs(:send_message)
  end

  context '#index' do
    before :each do
      app = Factory(:app)
      app1 = Factory(:app)
      app2 = Factory(:app)
      app3 = Factory(:app)

      offer1 = app1.primary_offer
      offer1.third_party_data = 'package.name.1'
      offer1.save
      offer2 = app2.primary_offer
      offer2.third_party_data = 'package.name.2'
      offer2.save
      offer3 = app3.primary_offer
      offer3.third_party_data = 'package.name.3'
      offer3.save

      device = Factory(:device)
      device.sdkless_clicks = { offer1.third_party_data => { 'click_time' => (Time.zone.now - 1.hour).to_i, 'item_id' => offer1.id },
                                offer2.third_party_data => { 'click_time' => (Time.zone.now - 2.hours).to_i, 'item_id' => offer2.id }}

      @params = { :app_id           => app.id,
                  :udid             => device.key,
                  :sdk_type         => 'offers',
                  :library_version  => SDKLESS_MIN_LIBRARY_VERSION,
                  :package_names    => "#{offer1.third_party_data},#{offer2.third_party_data},#{offer3.third_party_data}",
                  :verifier         => 'verifier',
                }

      controller.stubs(:generate_verifier).returns('verifier')
      Device.stubs(:new).returns(device)
    end

    context 'without required parameter values' do
      it "returns an error when udid is omitted" do
        @params.delete(:udid)
        get(:index, @params)
        response.body.should include('missing required params')
      end

      it "returns an error when app_id is omitted" do
        @params.delete(:app_id)
        get(:index, @params)
        response.body.should include('missing required params')
      end

      it "returns an error when library_version is omitted" do
        @params.delete(:library_version)
        get(:index, @params)
        response.body.should include('missing required params')
      end

      it "returns an error when sdk_type is omitted" do
        @params.delete(:sdk_type)
        get(:index, @params)
        response.body.should include('missing required params')
      end

      it "returns an error when verifier is omitted" do
        @params.delete(:verifier)
        get(:index, @params)
        response.body.should include('missing required params')
      end

      it "returns an error when package_names is omitted" do
        @params.delete(:package_names)
        get(:index, @params)
        response.body.should include('missing required params')
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
      it "returns a 200 OK when parameters are valid" do
        puts @params.inspect
        get(:index, @params)
        response.response_code.should == 200
      end

      # it "creates click models for sdkless clicks stored on device model"
      #
      # it "doesn't create click models for package names not stored on device model"
      #
      # it "adds sdkless clicks to SQS conversion queue"
      #
      # it "removes queued sdkless clicks from device model"
      #
      # it "creates a web request for this apps_installed call"
    end
  end
end
