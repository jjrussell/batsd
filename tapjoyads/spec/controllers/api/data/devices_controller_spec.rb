require 'spec_helper'

describe Api::Data::DevicesController do
  describe '#show' do
    before :each do
      @device = FactoryGirl.create(:device)
    end

    it 'looks up the object' do
      get(:show, :id => @device.id)
      assigns(:object).id.should == @device.id
    end

    context 'when changes are present' do
      before :each do
        @device = FactoryGirl.build(:device, :banned => true)
        @params = {
          :id           => @device.id,
          :sync_changes => { :banned => false }.to_json,
          :create_new   => true
        }
        Device.should_receive(:new).with(:key => @device.id).and_return(@device)
      end

      it 'merges the device attributes and saves it' do
        @device.should_receive(:save)
        get(:show, @params)
        @device.banned.should be_false
      end

      context 'but no create_new flag' do
        it 'doesnt save the device' do
          @params[:create_new] = false
          @device.should_not_receive(:save)
          get(:show, @params)
        end
      end
    end
  end

  describe '#set_last_run_time' do
    before :each do
      @device = FactoryGirl.create(:device)
      Device.should_receive(:new).with(:key => @device.id).and_return(@device)
    end

    context 'with no app_id' do
      it 'returns an error' do
        post(:set_last_run_time, :id => @device.id)
        JSON.parse(response.body)["success"].should be_false
      end
    end

    it 'sets the last app run time' do
      @device.should_receive(:set_last_run_time!)
      post(:set_last_run_time, {:id => @device.id, :app_id => 'TEST_APP'})
    end
  end
end
