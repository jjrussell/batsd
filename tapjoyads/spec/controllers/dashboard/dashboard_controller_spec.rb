require 'spec_helper'

describe Dashboard::DashboardController do
  before :each do
    activate_authlogic
    @admin = FactoryGirl.create(:admin)
    @user  = FactoryGirl.create(:user)
    @admin_partner = FactoryGirl.create(:partner, :users => [ @admin ])
    @user_partner  = FactoryGirl.create(:partner, :users => [ @user ])
  end

  describe '#find_app' do
    before :each do
      @user_app  = FactoryGirl.create(:app, :partner => @user_partner)
      @admin_app = FactoryGirl.create(:app, :partner => @admin_partner)
    end

    context "when given a regular user" do
      before :each do
        login_as(@user)
      end

      it 'finds my app' do
        @controller.send(:find_app, @user_app.id).should == @user_app
      end

      it 'cannot find other apps' do
        @controller.send(:find_app, @admin_app.id, :redirect_on_nil => false).should be_nil
      end
    end

    context "when given an admin user" do
      before :each do
        login_as(@admin)
      end

      it 'finds any app' do
        @controller.send(:find_app, @user_app.id).should  == @user_app
      end
    end
  end
end
