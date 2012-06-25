require 'spec_helper'

describe Dashboard::Tools::GamerDevicesController do
  let(:gamer)         { FactoryGirl.create(:gamer) }
  let(:gamer_device)  { FactoryGirl.create(:gamer_device, :gamer => gamer) }
  let(:params)        { { :id       => gamer_device.id,
                          :gamer_id => gamer.id } }
  
  before :each do
    ExternalPublisher.stub(:load_all).and_return(nil)
  end
  
  PERMISSIONS_MAP = {
    :edit => {
      :permissions => {
        :account_manager          => true,
        :admin                    => true,
        :agency                   => false,
        :customer_service_manager => true,
        :customer_service         => true,
        :devices                  => false,
        :executive                => false,
        :file_sharer              => false,
        :games_editor             => false,
        :hr                       => false,
        :money                    => false,
        :ops                      => false,
        :products                 => false,
        :partner                  => false,
        :partner_change           => false,
        :payops                   => false,
        :payout_manager           => false,
        :reporting                => false,
        :role_manager             => false,
        :sales_rep_manager        => false,
        :tools                    => false
      }
    },
    
    :new => {
      :permissions => {
        :account_manager          => true,
        :admin                    => true,
        :agency                   => false,
        :customer_service_manager => true,
        :customer_service         => true,
        :devices                  => false,
        :executive                => false,
        :file_sharer              => false,
        :games_editor             => false,
        :hr                       => false,
        :money                    => false,
        :ops                      => false,
        :products                 => false,
        :partner                  => false,
        :partner_change           => false,
        :payops                   => false,
        :payout_manager           => false,
        :reporting                => false,
        :role_manager             => false,
        :sales_rep_manager        => false,
        :tools                    => false
      }
    },
    
    :update => {
      :permissions => {
        :account_manager          => true,
        :admin                    => true,
        :agency                   => false,
        :customer_service_manager => true,
        :customer_service         => true,
        :devices                  => false,
        :executive                => false,
        :file_sharer              => false,
        :games_editor             => false,
        :hr                       => false,
        :money                    => false,
        :ops                      => false,
        :products                 => false,
        :partner                  => false,
        :partner_change           => false,
        :payops                   => false,
        :payout_manager           => false,
        :reporting                => false,
        :role_manager             => false,
        :sales_rep_manager        => false,
        :tools                    => false
      }
    },
  } unless defined? PERMISSIONS_MAP
  
  it_behaves_like "a controller with permissions"

  describe "#new" do
    context "when logged in as an admin user" do
      include_context 'logged in as user type', :admin
    
      it "redirects to gamer management tool if no gamer_id is specified" do
        get :new
        response.should redirect_to(tools_gamers_path)
      end
    end
  end

  describe "#update" do
    context "when logged in as an admin user" do
      include_context 'logged in as user type', :admin
    
      it "redirects to gamer management tool for associated gamer after update" do
        put(:update, params)
        response.should redirect_to(tools_gamer_path(gamer))
      end
    
      it "allows a gamer device's name to be updated" do
        params['gamer_device'] = { :name => 'New Name' }
        put(:update, params)
        gamer_device.reload
        gamer_device.name.should == 'New Name'
      end
    
      it "allows a gamer device's type to be updated" do
        params['gamer_device'] = { :device_type => 'ipod' }
        put(:update, params)
        gamer_device.reload
        gamer_device.device_type.should == 'ipod'
      end
    end
  end
end
