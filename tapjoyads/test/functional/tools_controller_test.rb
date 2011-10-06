require 'test_helper'

class ToolsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  context "with a non-logged in user" do
    should "redirect to login page" do
      get :index
      assert_redirected_to(login_path(:goto => tools_path))
    end
  end

  context "with an unauthorized user" do
    setup do
      @user = Factory(:agency_user)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      login_as(@user)
    end

    context "accessing tools index" do
      should "redirect to dashboard" do
        get :index
        assert_redirected_to(dashboard_root_path)
      end
    end
  end

  context "with an admin user" do
    setup do
      @user = Factory(:admin)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      login_as(@user)
    end

    context "accessing tools index" do
      should "render appropriate page" do
        get :index
        assert_template "tools/index"
      end
    end
  end
end
