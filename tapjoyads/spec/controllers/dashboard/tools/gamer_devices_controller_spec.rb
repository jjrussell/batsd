require 'spec/spec_helper'

describe Dashboard::Tools::GamerDevicesController do
  before :each do
    activate_authlogic

    gamer = Factory :gamer
    @params = { :gamer_id => gamer.id }
  end

  describe "#new" do
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
end
