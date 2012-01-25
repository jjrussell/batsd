require 'spec/spec_helper'

describe AppsController do
  before :each do
    fake_the_web
    activate_authlogic
  end

  describe '#index' do
    context 'with an admin user' do
      before :each do
        user = Factory(:admin)
        @partner = Factory(:partner,
          :pending_earnings => 10000,
          :balance => 10000,
          :users => [user]
        )
        Factory(:app, :partner => @partner)
        Factory(:app, :partner => @partner)
        login_as(user)
      end

      it 'displays their own app' do
        get 'index'
        response.should be_redirect
        @partner.apps.should include(assigns(:app))
      end
    end
  end

  describe '#show' do
    context 'with an admin user' do
      before :each do
        user = Factory(:admin)
        @partner = Factory(:partner,
          :pending_earnings => 10000,
          :balance => 10000,
          :users => [user]
        )
        Factory(:app, :partner => @partner)
        Factory(:app, :partner => @partner)
        login_as(user)
      end

      it 'displays apps from another partner' do
        someone_else = Factory(:partner,
          :pending_earnings => 10000,
          :balance => 10000
        )
        not_my_app = Factory(:app, :partner => someone_else)
        get 'show', :id => not_my_app.id
        response.should be_success
      end

      it "displays the last app visited" do
        last_app = @partner.apps.last
        get 'show', :id => last_app.id
        last_app.should == assigns(:app)
        last_app.id.should == session[:last_shown_app]
        get 'index'
        last_app.should == assigns(:app)
      end
    end
  end

  describe "A User with apps" do
    before :each do
      user = Factory(:user)
      @partner = Factory(:partner,
        :pending_earnings => 10000,
        :balance => 10000,
        :users => [user]
      )
      Factory(:app, :partner => @partner)
      Factory(:app, :partner => @partner)
      login_as(user)
    end

    describe "accessing apps index" do
      it "should be shown an app they own" do
        get 'index'
        response.should be_redirect
        @partner.apps.should include(assigns(:app))
      end
    end

    describe "accessing app show" do
      it "should be shown last app visited" do
        last_app = @partner.apps.last
        get 'show', :id => last_app.id
        last_app.should == assigns(:app)
        last_app.id.should == session[:last_shown_app]
        get 'index'
        last_app.should == assigns(:app)
      end

      it "should not see someone else's app" do
        someone_else = Factory(:partner,
          :pending_earnings => 10000,
          :balance => 10000
        )
        not_my_app = Factory(:app, :partner => someone_else)
        lambda {
          get 'show', :id => not_my_app.id
        }.should raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "Users without apps" do
    before :each do
      user = Factory(:admin)
      @partner = Factory(:partner,
        :pending_earnings => 10000,
        :balance => 10000,
        :users => [user]
      )
      login_as(user)
    end

    describe "accessing apps index" do
      it "should redirect to app creation page" do
        get 'index'
        response.should redirect_to(new_app_path)
      end
    end

    describe "accessing app show" do
      it "should redirect to app creation page" do
        someone_else = Factory(:partner,
          :pending_earnings => 10000,
          :balance => 10000
        )
        not_my_app = Factory(:app, :partner => someone_else)
        get 'show', :id => not_my_app.id
        response.should redirect_to(new_app_path)
      end
    end
  end
end
