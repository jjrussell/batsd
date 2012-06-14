require 'spec_helper'

describe Dashboard::Tools::GamerDevicesController do
  let(:gamer) { FactoryGirl.create(:gamer) }
  before :each do
    activate_authlogic
    ExternalPublisher.stub(:load_all).and_return(nil)
  end

  describe "#new" do
    let(:params) { { :gamer_id => gamer.id } }

    context "when logged in as customer service" do
      before :each do
        user = FactoryGirl.create(:customer_service_user)
        login_as user
      end

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
      before :each do
        user = Factory :account_mgr_user
        login_as user
      end

      it "allows access" do
        get(:new, params)
        response.should be_success
      end
    end

    context "when logged in as a partner" do
      before :each do
        user = Factory :partner_user
        login_as user
      end

      it "disallows access" do
        get(:new, params)
        response.should_not be_success
      end
    end
  end

  describe "#edit" do
    let(:params) { device = FactoryGirl.create(:device)
                   gamer_device = GamerDevice.new(:device => device, :gamer => gamer)
                   gamer_device.save!
                   { :id => gamer_device.id } }

    context "when logged in as customer service" do
      before :each do
        user = FactoryGirl.create(:customer_service_user)
        login_as user
      end

      it "allows access" do
        get(:edit, params)
        response.should be_success
      end
    end

    context "when logged in as an account manager" do
      before :each do
        user = FactoryGirl.create(:account_mgr_user)
        login_as user
      end

      it "allows access" do
        get(:edit, params)
        response.should be_success
      end
    end

    context "when logged in as a partner" do
      before :each do
        user = Factory :partner_user
        login_as user
      end

      it "disallows access" do
        get(:edit, params)
        response.should_not be_success
      end
    end
  end

  describe "#update" do
    let(:gamer_device) {
      device = FactoryGirl.create(:device)
      gamer_device = GamerDevice.new(:device => device, :gamer => gamer, :device_type => 'iphone')
      gamer_device.save!
      gamer_device
    }
    
    let(:params) { { :id => gamer_device.id } }

    context "when logged in as customer service" do
      before :each do
        user = FactoryGirl.create(:customer_service_user)
        login_as user
      end

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
      before :each do
        user = FactoryGirl.create(:account_mgr_user)
        login_as user
      end

      it "redirects to gamer management tool for associated gamer after update" do
        put(:update, params)
        response.should redirect_to(tools_gamer_path(gamer))
      end
    end

    context "when logged in as a partner" do
      before :each do
        user = Factory :partner_user
        login_as user

        put(:update, params)
      end

      it "disallows access" do
        response.should_not be_success
      end
    end
  end
end
