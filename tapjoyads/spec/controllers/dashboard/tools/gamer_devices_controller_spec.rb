require 'spec_helper'

describe Dashboard::Tools::GamerDevicesController do
  let(:gamer)         { FactoryGirl.create(:gamer) }
  let(:gamer_device)  { FactoryGirl.create(:gamer_device, :gamer => gamer) }
  let(:params)        { { :id       => gamer_device.id,
                          :gamer_id => gamer.id } }
  
  before :each do
    ExternalPublisher.stub(:load_all).and_return(nil)
  end

  describe "#new" do
    context "when logged in as a customer service user" do
      include_context 'logged in as user type', :customer_service
    
      it "allows access" do
        get(:new, params)
        response.should be_success
      end
    
      it "redirects to gamer management tool if no gamer_id is specified" do
        get :new
        response.should redirect_to(tools_gamers_path)
      end
    end

    context "when logged in as an account manager" do
      include_context 'logged in as user type', :account_manager
    
      it "allows access" do
        get(:new, params)
        response.should be_success
      end
    end

    context "when logged in as a partner" do
      include_context 'logged in as user type', :partner
      
      it "disallows access" do
        get(:new, params)
        response.should_not be_success
      end
    end
  end

  describe "#edit" do
    context "when logged in as a customer service user" do
      include_context 'logged in as user type', :customer_service
    
      it "allows access" do
        get(:edit, params)
        response.should be_success
      end
    end

    context "when logged in as an account manager" do
      include_context 'logged in as user type', :account_manager
    
      it "allows access" do
        get(:edit, params)
        response.should be_success
      end
    end

    context "when logged in as a partner" do
      include_context 'logged in as user type', :partner
      
      it "disallows access" do
        get(:edit, params)
        response.should_not be_success
      end
    end
  end

  describe "#update" do
    context "when logged in as a customer service user" do
      include_context 'logged in as user type', :customer_service
    
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
    
    context "when logged in as an account manager" do
      include_context 'logged in as user type', :account_manager
    
      it "redirects to gamer management tool for associated gamer after update" do
        put(:update, params)
        response.should redirect_to(tools_gamer_path(gamer))
      end
    end
    
    context "when logged in as a partner" do
      include_context 'logged in as user type', :partner
    
      it "disallows access" do
        put(:update, params)
        response.should_not be_success
      end
    end
  end
end
