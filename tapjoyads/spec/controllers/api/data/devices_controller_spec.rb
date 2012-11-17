require 'spec_helper'

describe Api::Data::DevicesController do
  before :each do
    Device.any_instance.stub(:external_publishers).and_return([])
    Device.any_instance.stub(:first_rewardable_currency_id).and_return(nil)
    ExternalPublisher.stub(:load_all).and_return([])
  end

  describe '#verify_auth_token' do
    before :each do
      @device = FactoryGirl.create(:device)

      @timestamp = Time.zone.now
      @well_formed_params = { :id => @device.id, :data => 'TEST_DATA' }
      Signage::ExpiringSignature.new('hmac_sha256', Rails.configuration.tapjoy_api_key).sign_hash!(@well_formed_params)
    end

    it 'succeeds for a well formed request' do
      Device.should_receive(:new).with(:key => @device.id).and_return(@device)
      get(:show, {:id => @device.id}.merge(@well_formed_params))
      JSON.parse(response.body)["success"].should be_true
    end

    it 'fails for invalid hmac digest' do
      @well_formed_params[:signature] = 'INVALID_DIGEST'
      get(:show, {:id => @device.id}.merge(@well_formed_params))
      response.response_code.should == 403
    end

    it 'fails for an altered request' do
      @well_formed_params[:data] = 'NEW_DATA'
      get(:show, {:id => @device.id}.merge(@well_formed_params))
      response.response_code.should == 403
    end

    it 'expires after 300 seconds' do
      Time.stub(:now).and_return(@timestamp + 4401.seconds)
      get(:show, {:id => @device.id}.merge(@well_formed_params))
      response.response_code.should == 403
    end
  end

  describe '#show' do
    before :each do
      @device = FactoryGirl.create(:device)
      @controller.stub(:verify_signature).and_return(true)
    end

    it 'looks up the object' do
      Device.should_receive(:find).with(@device.id).and_return(@device)
      get(:show, :id => @device.id)
    end

    context 'when changes are present' do
      before :each do
        @device = FactoryGirl.build(:device, :banned => true)
        @params = {
          :id           => @device.id,
          :sync_changes => { :banned => false }.to_json,
          :create_new   => true
        }
        Device.should_receive(:find).with(@device.id).and_return(@device)
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
      @controller.stub(:verify_signature).and_return(true)
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
