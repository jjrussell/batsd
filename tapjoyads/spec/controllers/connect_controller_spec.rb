require 'spec_helper'

describe ConnectController do
  render_views

  describe '#index' do
    context 'with required parameters' do
      before :each do
        app = FactoryGirl.create(:app)
        offer = app.primary_offer
        device = FactoryGirl.create(:device)
        device.sdkless_clicks = { offer.third_party_data => { 'click_time' => (Time.zone.now - 1.hour).to_i, 'item_id' => offer.id }}

        @params = { :app_id => 'test_app',
                    :udid   => 'test_device' }

        Device.stub(:new).and_return(device)
      end

      it "returns an XML response" do
        get(:index, @params)
        response.content_type.should == 'application/xml'
      end

      it "returns a successful response" do
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

      context 'blacklisted udid' do
        before :each do
          @params = { :app_id     => 'test_app',
                      :udid       => '358673013795895'}
        end
        it 'returns 403 forbidden' do
          get(:index, @params)
          response.response_code.should == 403
        end
      end

      context 'by an admin device' do
        it 'updates the AdminDeviceLastRun for this udid and app_id' do
          Device.any_instance.stub(:last_run_time_tester?) { true }
          get(:index, @params.merge(:connection_type => 'awesome'))
          response.body.should include('Success')

          last_run = AdminDeviceLastRun.for(@params).first
          last_run.ip_address.should == '0.0.0.0'
          last_run.connection_type.should == 'awesome'
        end
      end
    end

    context 'without required parameters' do
      it 'should 400 when udid is blank' do
        get(:index, { :app_id => 'test_app', :udid => '' })
        should respond_with 400
      end
      it 'should have a missing params message' do
        get(:index, { :app_id => 'test_app', :udid => '' })
        response.body.should == 'missing parameters: udid'
      end
      it 'should 400 when udid and app_id is blank' do
        get(:index, { :app_id => '', :udid => '' })
        should respond_with 400
      end
      it 'should have a missing params message' do
        get(:index, { :app_id => '', :udid => '' })
        response.body.should == 'missing parameters: app_id, udid'
      end
    end

    context 'when device identifiers are provided' do
      before :each do
        @params = { :app_id      => 'test_app',
                    :sha2_udid   => 'sha2_test_device' }
      end

      context 'when the identifier is corrupt' do
        before :each do
          identifier = FactoryGirl.create(:device_identifier, :udid => 'device_identifier.232132121321')
          DeviceIdentifier.stub(:new).and_return(identifier)
          @device = FactoryGirl.create(:device)
        end

        it 'doesnt return the corrupt udid' do
          Device.should_receive(:new).with(
            :key => 'sha2_test_device',
            :is_temporary => true
          ).at_least(:once).and_return(@device)
          get(:index, @params)
        end
      end

      context 'when the lookup succeeds' do
        before :each do
          @device = FactoryGirl.create(:device)
          identifier = FactoryGirl.create(:device_identifier, :udid => 'test_device')
          DeviceIdentifier.stub(:new).and_return(identifier)
        end

        it 'returns success' do
          Device.stub(:new).and_return(@device)
          get(:index, @params)
          response.body.should include('Success')
        end
      end

      context 'when the lookup fails' do
        before :each do
          @device = FactoryGirl.create(:device)
        end

        it 'creates a temporary device' do
          Device.should_receive(:new).
            with(:key => 'sha2_test_device', :is_temporary => true).
            at_least(1).times.
            and_return(@device)

          get(:index, @params)
          response.body.should include('Success')
        end
      end
    end
  end
end
