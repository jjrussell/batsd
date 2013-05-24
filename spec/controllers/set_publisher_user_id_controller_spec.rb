require 'spec_helper'

describe SetPublisherUserIdController do
  describe '#index' do
    before :each do
      @device = FactoryGirl.create(:device)
      @params = { :app_id => 'test_app',
                  :udid => 'test_udid',
                  :publisher_user_id => 'test_pub_id',
                  :display_multiplier => 3, }
    end

    it 'sets the publisher_user_id' do
      Device.should_receive(:new).twice.with(:key => 'test_udid', :is_temporary => false).and_return(@device)
      @device.should_receive(:set_publisher_user_id)
      @device.should_receive(:set_display_multiplier)
      get(:index, @params)
      response.should be_success
    end

    context 'when a lookup fails' do
      before :each do
        @params = { :app_id => 'test_app',
                    :sha1_mac_address => 'sha1_mac',
                    :publisher_user_id => 'test_pub_id',
                    :display_multiplier => 3 }
      end

      it 'creates a temporary device' do
        Device.should_receive(:new).twice.with(:key => 'sha1_mac', :is_temporary => true).and_return(@device)
        get(:index, @params)
        response.should be_success
      end
    end
  end
end
