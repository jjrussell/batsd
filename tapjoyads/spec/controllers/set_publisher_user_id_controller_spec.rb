require 'spec_helper'

describe SetPublisherUserIdController do
  describe '#index' do
    before :each do
      @device = FactoryGirl.create(:device)
      @params = { :app_id => 'test_app',
                  :udid => @device.key,
                  :publisher_user_id => 'test_pub_id',
                  :display_multiplier => 3, }
    end

    it 'sets the publisher_user_id' do
      Device.should_receive(:find_by_device_id).and_return(@device)
      @device.should_receive(:set_publisher_user_id)
      @device.should_receive(:set_display_multiplier)
      get(:index, @params)
      response.should be_success
    end

    context 'when a lookup fails but identifier exists' do
      before :each do
        Device.stub(:new).and_return(@device)
        device_identifier = FactoryGirl.create(:device_identifier)
        DeviceIdentifier.stub(:new).and_return(device_identifier)
        DeviceIdentifier.any_instance.stub(:new_record?).and_return(false)
        DeviceIdentifier.any_instance.stub(:device_id).and_return('sha1_mac')
        @params = { :app_id => 'test_app',
                    :sha1_mac_address => 'sha1_mac',
                    :publisher_user_id => 'test_pub_id',
                    :display_multiplier => 3 }
      end

      it 'creates a temporary device' do
        Device.should_receive(:new).with(:key => 'sha1_mac').and_return(@device)
        get(:index, @params)
        response.should render_template('layouts/success')
      end
    end
  end
end
