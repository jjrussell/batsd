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


      # The connect call must report the unique identifier for the calling
      # device that is "least invasive" to the user's privacy. This is the
      # priority of identifiers that the connect call receives:
      IDENTIFIER_PRIORITIES = [:advertising_id, :open_udid, :android_id, :serial_id, :mac_address, :udid]

      def self.generate_params_for(*identifiers)
        params = {}

        identifiers.each do |id|
          params[id] = id.to_s
        end

        params
      end

      def self.preferred_identifier_for(*identifiers)
        IDENTIFIER_PRIORITIES.each do |id|
          return id if identifiers.include?(id)
        end
      end

      def self.all_combinations_for(identifiers)
        cs = []
        1.upto(identifiers.size) do |i|
          cs += identifiers.combination(i).to_a
        end

        return cs
      end

      all_combinations_for(IDENTIFIER_PRIORITIES).each do |identifiers|

        context "and those identifiers are #{identifiers.to_sentence}" do
          expected_identifier = preferred_identifier_for(*identifiers)
          let(:click) do
            mock('Click',
              :rewardable? => true,
              :new_record? => false,
              :key => 'key',
              :id => 'click_id',
              :offer_id => 'offer_id'
            )
          end
          let(:device) do
            FactoryGirl.create(:device).tap do |this|
              Device.stub(:new).and_return(this)
            end
          end
          let(:params) { @params.merge(self.class.generate_params_for(*identifiers)) }
          before(:each) do
            device.stub(:has_app?).and_return false
            controller.stub(:valid_advertising_id?).and_return(true)
            Click.stub(:new).and_return(click)
          end

          it "includes the #{expected_identifier} in the conversion tracking request" do
            Sqs.should_receive(:send_message) do |queue, json_params|
              queue.should be QueueNames::CONVERSION_TRACKING
              h = JSON.parse(json_params)
              h['device_identifier']['id'].should == expected_identifier.to_s
            end

            get(:index, params)
          end

        end
      end
    end
  end
end
