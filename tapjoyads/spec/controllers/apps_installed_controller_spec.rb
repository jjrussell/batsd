require 'spec_helper'

describe AppsInstalledController do
  render_views

  context '#index' do
    before :each do
      @app = FactoryGirl.create(:app)
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


      controller.stub(:generate_verifier).and_return('verifier')
    end

    context 'without required parameter values' do
      context 'with tapjoy_device_id' do
        before :each do
          @params = { :app_id           => @app.id,
                      :tapjoy_device_id => @device.key,
                      :sdk_type         => 'offers',
                      :library_version  => SDKLESS_MIN_LIBRARY_VERSION,
                      :package_names    => "#{@offer1.third_party_data},#{@offer2.third_party_data}",
                      :verifier         => 'verifier'
                    }
        end
        it "returns an error when udid is omitted" do
          @params.delete(:tapjoy_device_id)
          get(:index, @params)
          response.body.should include('record not found')
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
      context 'any other identifier (udid)' do
        before :each do
          @params = { :app_id           => @app.id,
                      :udid             => @device.key,
                      :sdk_type         => 'offers',
                      :library_version  => SDKLESS_MIN_LIBRARY_VERSION,
                      :package_names    => "#{@offer1.third_party_data},#{@offer2.third_party_data}",
                      :verifier         => 'verifier'
                    }
          @device = FactoryGirl.create(:device)
        end
        it "returns an error when udid is omitted" do
          @params.delete(:udid)
          get(:index, @params)
          response.body.should include('record not found')
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
          Device.stub(:find).and_return(@device)
          @params[:verifier] = 'invalid'
          get(:index, @params)
          response.body.should include('invalid verifier')
        end

        it "returns an error if API does not support SDK-less clicks" do
          Device.stub(:find).and_return(@device)
          @params[:sdk_type] = 'connect'
          get(:index, @params)
          response.body.should include('sdkless not supported')
        end
      end
    end
    context 'with required parameters' do
      context 'with tapjoy_device_id' do
        before :each do
          @params = { :app_id           => @app.id,
                      :tapjoy_device_id => @device.key,
                      :sdk_type         => 'offers',
                      :library_version  => SDKLESS_MIN_LIBRARY_VERSION,
                      :package_names    => "#{@offer1.third_party_data},#{@offer2.third_party_data}",
                      :verifier         => 'verifier'
                    }
          Device.stub(:new).and_return(@device)
        end
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
      context 'with a different identifier (udid)' do
        before :each do
          @params = { :app_id           => @app.id,
                      :udid             => @device.key,
                      :sdk_type         => 'offers',
                      :library_version  => SDKLESS_MIN_LIBRARY_VERSION,
                      :package_names    => "#{@offer1.third_party_data},#{@offer2.third_party_data}",
                      :verifier         => 'verifier'
                    }
          Device.stub(:find).and_return(@device)
        end
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
      context 'with a different identifier (advertising_id)' do
        context 'device identifier found (device exists)' do
          before :each do
            @params = { :app_id           => @app.id,
                        :advertising_id   => @device.key,
                        :sdk_type         => 'offers',
                        :library_version  => SDKLESS_MIN_LIBRARY_VERSION,
                        :package_names    => "#{@offer1.third_party_data},#{@offer2.third_party_data}",
                        :verifier         => 'verifier'
                      }
            device_identifier = FactoryGirl.create(:device_identifier)
            DeviceIdentifier.stub(:new).and_return(device_identifier)
            DeviceIdentifier.any_instance.stub(:new_record?).and_return(false)
            DeviceIdentifier.any_instance.stub(:device_id).and_return(@device.key)
            Device.stub(:new).and_return(@device)
          end
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
        context 'device identifier not found (device does not exist)' do
          before :each do
            @params = { :app_id           => @app.id,
                        :advertising_id   => @device.key,
                        :sdk_type         => 'offers',
                        :library_version  => SDKLESS_MIN_LIBRARY_VERSION,
                        :package_names    => "#{@offer1.third_party_data},#{@offer2.third_party_data}",
                        :verifier         => 'verifier'
                      }
            device_identifier = FactoryGirl.create(:device_identifier)
            DeviceIdentifier.stub(:new).and_return(device_identifier)
            DeviceIdentifier.any_instance.stub(:new_record?).and_return(true)
          end

          it "returns a 400 since missing valid params" do
            get(:index, @params)
            should respond_with 400
          end

          it "has a missing required params message in the response body" do
            get(:index, @params)
            response.body.should include('record not found')
          end
        end
      end
    end
  end
end
