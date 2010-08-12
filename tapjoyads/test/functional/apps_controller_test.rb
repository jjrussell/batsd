require 'test_helper'

class AppsControllerTest < ActionController::TestCase
  setup :activate_authlogic
  context "Apps" do
    setup do
      @user = Factory(:admin)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      Factory(:app, :partner => @partner)
      Factory(:app, :partner => @partner)
      login_as(@user)
    end

    context "Index" do
      should "show first app belonging to a user" do
        get 'index'
        assert_response(:success)
        assert_equal @partner.apps.first, assigns(:app)
      end

      should "show last app user visited" do
        get 'show', :id => @partner.apps.last.id
        assert_equal @partner.apps.last, assigns(:app)
        assert_equal @partner.apps.last.id, session[:last_shown_app]
        get 'index'
        assert_equal @partner.apps.last, assigns(:app)
      end
    end

    context "Show" do
      should "not display someone else's app" do

      end
    end
  end
end
