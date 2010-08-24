require 'test_helper'

class AppsControllerTest < ActionController::TestCase
  setup :activate_authlogic
  context "Users with apps" do
    setup do
      @user = Factory(:admin)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      Factory(:app, :partner => @partner)
      Factory(:app, :partner => @partner)
      login_as(@user)
    end

    context "accessing apps index" do
      should "be shown first app they own" do
        get 'index'
        assert_response(:success)
        assert_equal @partner.apps.first, assigns(:app)
      end
    end

    context "accessing app show" do
      should "be shown last app visited" do
        get 'show', :id => @partner.apps.last.id
        assert_equal @partner.apps.last, assigns(:app)
        assert_equal @partner.apps.last.id, session[:last_shown_app]
        get 'index'
        assert_equal @partner.apps.last, assigns(:app)
      end

      should "not see someone else's app" do
        someone_else = Factory(:partner, :pending_earnings => 10000, :balance => 10000)
        not_my_app = Factory(:app, :partner => someone_else)
        get 'show', :id => not_my_app.id
        assert_redirected_to(apps_path)
      end
    end
  end

  context "Users without apps" do
    setup do
      @user = Factory(:admin)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      login_as(@user)
    end

    context "accessing apps index" do
      should "redirect to app creation page" do
        get 'index'
        assert_redirected_to(new_app_path)
      end
    end

    context "accessing app show" do
      should "redirect to app creation page" do
        someone_else = Factory(:partner, :pending_earnings => 10000, :balance => 10000)
        not_my_app = Factory(:app, :partner => someone_else)
        get 'show', :id => not_my_app.id
        assert_redirected_to(new_app_path)
      end
    end
  end
end
