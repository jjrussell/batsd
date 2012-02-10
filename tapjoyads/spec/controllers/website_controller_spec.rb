require 'spec_helper'

describe WebsiteController do
  before :each do
    activate_authlogic
    fake_the_web
    @admin = Factory(:admin)
    @user  = Factory(:user)
    @admin_partner = Factory(:partner, :users => [ @admin ])
    @user_partner  = Factory(:partner, :users => [ @user ])
  end

  describe '#find_app' do
    before :each do
      @user_app  = Factory(:app, :partner => @user_partner)
      @admin_app = Factory(:app, :partner => @admin_partner)
    end

    context "when given a regular user" do
      before :each do
        login_as(@user)
      end

      it 'finds my app' do
        @controller.send(:find_app, @user_app.id).should  == @user_app
      end

      it 'cannot find other apps' do
        expect {
          @controller.send(:find_app, @admin_app.id)
        }.to raise_exception(ActiveRecord::RecordNotFound)
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
