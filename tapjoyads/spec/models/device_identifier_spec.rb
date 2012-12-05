require 'spec_helper'

describe DeviceIdentifier do
  describe '.find_device_from_params' do
    before :each do
      @params = {
        :udid             => 'test_udid',
        :advertising_id   => 'test_advertising_id',
        :mac_address      => 'test_mac_address',
        :sha1_udid        => 'test_sha1_udid',
        :unused_param     => 'test_unused_param',
      }
    end
    context 'invalid device' do
      before :each do
        DeviceIdentifier.should_receive(:find_device_for_identifier).with('test_udid').and_return(nil)
        DeviceIdentifier.should_receive(:find_device_for_identifier).with('test_advertising_id').and_return(nil)
        DeviceIdentifier.should_receive(:find_device_for_identifier).with('test_mac_address').and_return(nil)
        DeviceIdentifier.should_receive(:find_device_for_identifier).with('test_sha1_udid').and_return(nil)
        DeviceIdentifier.should_not_receive(:find_device_for_identifier).with('test_unused_param')
      end
      it 'tries all possible lookups' do
        DeviceIdentifier.find_device_from_params(@params).should be_nil
      end
    end
    context 'valid device' do
      before :each do
        @device = FactoryGirl.create(:device)
        DeviceIdentifier.should_receive(:find_device_for_identifier).and_return(@device)
      end
      it 'returns the correct device' do
        DeviceIdentifier.find_device_from_params(@params).should == @device
      end
    end
  end

  describe '.find_device_for_identifier' do
    context 'with a valid device identifier' do
      before :each do
        @device = FactoryGirl.create(:device)
        @device_identifier = FactoryGirl.create(:device_identifier, :device_id => 'test_device_id')
        DeviceIdentifier.should_receive(:find).with('test_identifier', :consistent => true).and_return(@device_identifier)
        Device.should_receive(:find).with(@device_identifier.device_id).and_return(@device)
      end
      it 'tries to look up the right device' do
        DeviceIdentifier.find_device_for_identifier('test_identifier').should == @device
      end
    end

    context 'with a bad device identifier' do
      before :each do
        @device_identifier = FactoryGirl.create(:device_identifier, :udid => 'device_identifier.xxx')
        DeviceIdentifier.should_receive(:find).with('test_identifier', :consistent => true).and_return(@device_identifier)
        Device.should_not_receive(:find)
      end
      it 'does not return nil' do
        DeviceIdentifier.find_device_for_identifier('test_identifier').should be_nil
      end
    end
  end
end
