require 'spec_helper'

describe Dashboard::Tools::GamersController do
  before :each do
    activate_authlogic
  end

  describe "#index" do
    context "when logged in as customer service" do
      before :each do
        user = Factory :customer_service_user
        login_as user

        get :index
      end

      it "allows access" do
        response.should be_success
      end
    end

    context "when logged in as an account manager" do
      before :each do
        user = Factory :account_mgr_user
        login_as user

        get :index
      end

      it "allows access" do
        response.should be_success
      end
    end

    context "when logged in as a partner" do
      before :each do
        user = Factory :partner_user
        login_as user

        get :index
      end

      it "disallows access" do
        response.should_not be_success
      end
    end
  end

  describe "#show" do
    before :each do
      @gamer = Factory :gamer
      @params = { :id => @gamer.id }
    end

    context "when logged in as customer service" do
      before :each do
        user = Factory :customer_service_user
        login_as user
      end

      it "allows access" do
        get(:show, @params)
        response.should be_success
      end

      it "creates a gamer_profile for the gamer if one doesn't exist" do
        @gamer.gamer_profile.should be_nil
        get(:show, @params)
        assigns(:gamer).gamer_profile.should_not be_nil
      end
    end

    context "when logged in as an account manager" do
      before :each do
        user = Factory :account_mgr_user
        login_as user

        get(:show, @params)
      end

      it "allows access" do
        response.should be_success
      end
    end

    context "when logged in as a partner" do
      before :each do
        user = Factory :partner_user
        login_as user

        get(:show, @params)
      end

      it "disallows access" do
        response.should_not be_success
      end
    end
  end
end
