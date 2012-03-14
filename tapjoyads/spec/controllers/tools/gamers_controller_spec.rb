require 'spec/spec_helper'

describe Tools::GamersController do
  before :each do
    activate_authlogic
  end

  describe "#index" do
    context "when logged in as customer service" do
      before :each do
        user = Factory :customer_service_user
        login_as user

        get(:index)
      end

      it "allows access" do
        response.should be_success
      end
    end

    context "when logged in as an account manager" do
      before :each do
        user = Factory :account_mgr_user
        login_as user

        get(:index)
      end

      it "allows access" do
        response.should be_success
      end
    end

    context "when logged in as a partner" do
      before :each do
        user = Factory :partner_user
        login_as user

        get(:index)
      end

      it "disallows access" do
        response.should_not be_success
      end
    end
  end
end
