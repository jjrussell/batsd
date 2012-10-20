require 'spec_helper'

describe Dashboard::Tools::GamersController do
  before :each do
    activate_authlogic
  end

  describe "#index" do
    context "when logged in as customer service" do
      before :each do
        user = FactoryGirl.create(:user, :with_customer_service_role)
        login_as user

        get(:index)
      end

      it "allows access" do
        response.should be_success
      end
    end

    context "when logged in as an account manager" do
      before :each do
        user = FactoryGirl.create(:account_manager)
        login_as user

        get(:index)
      end

      it "allows access" do
        response.should be_success
      end
    end

    context "when logged in as a partner" do
      before :each do
        user = FactoryGirl.create(:user, :with_partner)
        login_as user

        get(:index)
      end

      it "disallows access" do
        response.should_not be_success
      end
    end
  end
end
