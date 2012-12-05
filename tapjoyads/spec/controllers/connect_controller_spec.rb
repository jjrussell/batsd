require 'spec_helper'

describe ConnectController do
  render_views

  describe '#index' do
    context 'without required parameters' do
      context 'device information missing' do
        it 'returns an error code' do
          get(:index, {:app_id => 'app_id_test_id'})
          response.response_code.should == 400
        end
      end

      context 'app_id missing' do
        it 'returns an error code' do
          get(:index, {:advertising_id => 'test_advertising_id'})
          response.response_code.should == 400
        end
      end
    end

    context 'with blacklisted udid' do
      before :each do
        @params = { :app_id     => 'app_id_test',
                    :udid       => '358673013795895'}
      end

      it 'returns 403 forbidden' do
        get(:index, @params)
        response.response_code.should == 403
      end
    end

    context 'with blacklisted advertising id' do
      before :each do
        @params = { :app_id         => 'app_id_test',
                    :advertising_id => '00000000-0000-0000-0000-000000000000'}
      end

      it 'returns 403 forbidden' do
        get(:index, @params)
        response.response_code.should == 403
      end
    end

    context 'new device' do
      context 'with required parameters' do
        context 'when udid is passed' do
          before :each do
            @device = FactoryGirl.create(:device, :has_tapjoy_id => true)
            @params = { :app_id => 'app_id_test',
                        :udid   => 'test_device'}

            @identifier = FactoryGirl.create(:device_identifier)
            @identifier.stub(:new_record?).and_return(true)
            Device.should_receive(:find_by_device_id).and_return(nil)
            DeviceIdentifier.should_receive(:find_device_from_params).and_return(nil)
            Device.should_receive(:new).and_return(@device)
            @device.should_receive(:udid=).with('test_device')
            @device.should_receive(:save).and_return(true)
          end

          it 'returns an XML response' do
            get(:index, @params)
            response.content_type.should == 'application/xml'
          end

          it 'returns a successful response' do
            get(:index, @params)
            response.body.should include('Success')
          end

          context 'with identifiers' do
            it 'ignores the identifiers' do
              TemporaryDevice.should_not_receive(:new)
              get(:index, @params.merge(:sha2_udid => 'test_sha2_udid'))
              response.body.should include('Success')
            end
          end
        end

        context 'with advertising id' do
          before :each do
            @device = FactoryGirl.create(:device)
            @params = { :app_id           => 'app_id_test',
                        :advertising_id   => 'test_advertising_id'}
            DeviceIdentifier.should_receive(:find_device_from_params).and_return(nil)
            Device.should_receive(:new).and_return(@device)
            @device.should_receive(:advertising_id=).with('test_advertising_id')
            @device.should_receive(:save).and_return(true)
          end

          it 'returns an XML response' do
            get(:index, @params)
            response.content_type.should == 'application/xml'
          end

          it 'returns a successful response' do
            get(:index, @params)
            response.body.should include('Success')
          end
        end

        context 'with mac_address' do
          before :each do
            @device = FactoryGirl.create(:device)
            @params = { :app_id       => 'app_id_test',
                        :mac_address   => 'test_mac_address'}
            Device.should_receive(:find_by_device_id).and_return(nil)
            DeviceIdentifier.should_receive(:find_device_from_params).and_return(nil)
            Device.should_receive(:new).and_return(@device)
            @device.should_receive(:mac_address=).with('test_mac_address')
            @device.should_receive(:save).and_return(true)
          end

          it 'returns an XML response' do
            get(:index, @params)
            response.content_type.should == 'application/xml'
          end

          it 'returns a successful response' do
            get(:index, @params)
            response.body.should include('Success')
          end
        end
      end

      context 'with identifiers only' do
        before :each do
          @device = FactoryGirl.create(:device)
          @params = { :app_id      => 'app_id_test',
                      :sha2_udid   => 'sha2_test_device' }
        end

        it 'creates a temporary device' do
          DeviceIdentifier.should_receive(:find_device_from_params).and_return(nil)
          Device.should_receive(:new).
            with(:key => 'sha2_test_device', :is_temporary => true).
            at_least(1).times.
            and_return(@device)

          get(:index, @params)
          response.body.should include('Success')
        end
      end
    end

    context 'an existing device' do
      context 'which is old style udid based' do
        before :each do
          @device = FactoryGirl.create(:device)
          @params = { :app_id   => 'app_id_test',
                      :udid     => 'test_udid' }

          Device.should_receive(:find).with('test_udid').and_return(@device)
          Device.should_not_receive(:new)
        end

        it 'should find the old styled device' do
          get(:index, @params)
          response.body.should include('Success')
        end
      end

      context 'which is new style tapjoy id based' do
        before :each do
          app = FactoryGirl.create(:app)
          offer = app.primary_offer
          @device = FactoryGirl.create(:device)
          @device.udid = 'test_udid'
          @device.sdkless_clicks = { offer.third_party_data => { 'click_time' => (Time.zone.now - 1.hour).to_i, 'item_id' => offer.id }}
          @device.save
          @params = { :app_id   => app.id,
                      :udid     => 'test_udid',
                      :tapjoy_device_id => @device.key }
          @controller.stub(:find_or_create_device).and_return(@device)
        end

        it 'should find the old styled device' do
          get(:index, @params)
          response.body.should include('Success')
        end

        context 'without SDK-less parameters' do
          it "doesn't return SDK-less click package names" do
            get(:index, @params)
            response.body.should_not include('PackageNames')
          end
        end

        context 'with SDK-less parameters' do
          before :each do
            controller.stub(:sdkless_supported?).and_return(true)
          end

          it "returns SDK-less click package names" do
            get(:index, @params)
            response.body.should include('PackageNames')
          end
        end

        context 'by an admin device' do
          it 'updates the AdminDeviceLastRun for this udid and app_id' do
            Device.any_instance.stub(:last_run_time_tester?) { true }
            @device.stub(:last_run_time_tester?).and_return(true)
            get(:index, @params.merge(:connection_type => 'awesome'))
            response.body.should include('Success')

            last_run = AdminDeviceLastRun.for(@params).first
            last_run.ip_address.should == '0.0.0.0'
            last_run.connection_type.should == 'awesome'
          end
        end
      end

      context 'when an identifier is provided' do
        before :each do
          @device = FactoryGirl.create(:device)
          @params = { :app_id      => 'app_id_test',
                      :sha2_udid   => 'sha2_test_device' }
          DeviceIdentifier.should_receive(:find_device_from_params).and_return(@device)
        end

        it 'looks up the device' do
          get(:index, @params)
          response.body.should include('Success')
        end
      end
    end
  end
end
