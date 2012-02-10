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

  context '#find_app' do
    before :each do
      @user_app  = Factory(:app, :partner => @user_partner)
      @admin_app = Factory(:app, :partner => @admin_partner)
    end

    it 'should only return my app' do
      login_as(@user)
      @controller.send(:find_app, @user_app.id).should  == @user_app
      lambda do
        @controller.send(:find_app, @admin_app.id)
      end.should raise_exception(ActiveRecord::RecordNotFound)
    end

    it 'should return any app for admin' do
      login_as(@admin)
      @controller.send(:find_app, @user_app.id).should  == @user_app
      @controller.send(:find_app, @admin_app.id).should == @admin_app
    end
  end
end
