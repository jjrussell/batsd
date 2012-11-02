require 'spec_helper'

describe Dashboard::Tools::GamerDevicesController do
  let(:gamer)         { FactoryGirl.create(:gamer) }
  let(:gamer_device)  { FactoryGirl.create(:gamer_device, :gamer => gamer) }
  let(:params)        { { :id           => gamer_device.id,
                          :gamer_device => { :gamer_id => gamer.id } } }

  PERMISSIONS_MAP = {
    :create   => { :allowed => [ :account_mgr, :admin, :customer_service_manager, :customer_service, :payout_manager, :payops ]},
    :edit     => { :allowed => [ :account_mgr, :admin, :customer_service_manager, :customer_service, :payout_manager, :payops ]},
    :new      => { :allowed => [ :account_mgr, :admin, :customer_service_manager, :customer_service, :payout_manager, :payops ]},
    :update   => { :allowed => [ :account_mgr, :admin, :customer_service_manager, :customer_service, :payout_manager, :payops ]},
  }

  it_behaves_like "a controller with permissions"

  before :each do
    controller.stub(:set_recent_partners)
  end

  describe "#new" do
    context "when logged in as an authorized user" do
      include_context 'logged in as user with role', :admin

      it "redirects to gamer management tool if no gamer_id is specified" do
        get :new
        response.should redirect_to(tools_gamers_path)
      end
    end
  end

  describe "#update" do
    context "when logged in as an authorized user" do
      include_context 'logged in as user with role', :admin

      it "redirects to gamer management tool for associated gamer after update" do
        put(:update, params)
        response.should redirect_to(tools_gamer_path(gamer))
      end

      it "allows a gamer device's name to be updated" do
        params[:gamer_device] = params[:gamer_device].merge(:name => 'New Name')
        put(:update, params)
        gamer_device.reload
        gamer_device.name.should == 'New Name'
      end

      it "allows a gamer device's type to be updated" do
        params[:gamer_device] = params[:gamer_device].merge(:device_type => 'ipod')
        put(:update, params)
        gamer_device.reload
        gamer_device.device_type.should == 'ipod'
      end
    end
  end
end
