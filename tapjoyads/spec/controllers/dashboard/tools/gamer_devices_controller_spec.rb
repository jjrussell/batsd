require 'spec/spec_helper'

describe Dashboard::Tools::GamerDevicesController do
  before :each do
    activate_authlogic
    ExternalPublisher.stubs(:load_all).returns(nil)

    @gamer = Factory :gamer
  end

  describe "#new" do
    before :each do
      @params = { :gamer_id => @gamer.id }
    end

    context "when logged in as customer service" do
      before :each do
        user = Factory :customer_service_user
        login_as user
      end

      it "allows access" do
        get(:new, @params)
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

        get(:new, @params)
      end

      it "allows access" do
        response.should be_success
      end
    end

    context "when logged in as a partner" do
      before :each do
        user = Factory :partner_user
        login_as user

        get(:new, @params)
      end

      it "disallows access" do
        response.should_not be_success
      end
    end
  end

  describe "#edit" do
    before :each do
      device = Factory :device
      gamer_device = GamerDevice.new(:device => device, :gamer => @gamer)
      gamer_device.save!

      @params = { :id => gamer_device.id }
    end

    context "when logged in as customer service" do
      before :each do
        user = Factory :customer_service_user
        login_as user
      end

      it "allows access" do
        get(:edit, @params)
        response.should be_success
      end
    end

    context "when logged in as an account manager" do
      before :each do
        user = Factory :account_mgr_user
        login_as user

        get(:edit, @params)
      end

      it "allows access" do
        response.should be_success
      end
    end

    context "when logged in as a partner" do
      before :each do
        user = Factory :partner_user
        login_as user

        get(:edit, @params)
      end

      it "disallows access" do
        response.should_not be_success
      end
    end
  end

  describe "#update" do
    before :each do
      device = Factory :device
      @gamer_device = GamerDevice.new(:device => device, :gamer => @gamer, :device_type => 'iphone')
      @gamer_device.save!

      @params = { :id => @gamer_device.id }
    end

    context "when logged in as customer service" do
      before :each do
        user = Factory :customer_service_user
        login_as user
      end

      it "redirects to gamer management tool for associated gamer after update" do
        put(:update, @params)
        response.should redirect_to(tools_gamer_path(@gamer))
      end

      it "allows a gamer device's name to be updated" do
        @params['gamer_device'] = { :name => 'New Name' }
        put(:update, @params)
        @gamer_device.reload
        @gamer_device.name.should == 'New Name'
      end

      it "allows a gamer device's type to be updated" do
        @params['gamer_device'] = { :device_type => 'ipod' }
        put(:update, @params)
        @gamer_device.reload
        @gamer_device.device_type.should == 'ipod'
      end
    end

    context "when logged in as an account manager" do
      before :each do
        user = Factory :account_mgr_user
        login_as user
      end

      it "redirects to gamer management tool for associated gamer after update" do
        put(:update, @params)
        response.should redirect_to(tools_gamer_path(@gamer))
      end
    end

    context "when logged in as a partner" do
      before :each do
        user = Factory :partner_user
        login_as user

        put(:update, @params)
      end

      it "disallows access" do
        response.should_not be_success
      end
    end
  end
end
