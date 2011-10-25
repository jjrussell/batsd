require 'test_helper'

class AppsControllerTest < ActionController::TestCase
  setup :activate_authlogic
  context "An admin user" do
    setup do
      @user = Factory(:admin)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      Factory(:app, :partner => @partner)
      Factory(:app, :partner => @partner)
      login_as(@user)
    end

    context "accessing apps index" do
      should "be shown an app they own" do
        get 'index'
        assert_response(:redirect)
        assert @partner.apps.include? assigns(:app)
      end
    end

    context "accessing app show" do
      should "be shown last app visited" do
        last_app = @partner.apps.last
        get 'show', :id => last_app.id
        assert_equal last_app, assigns(:app)
        assert_equal last_app.id, session[:last_shown_app]
        get 'index'
        assert_equal last_app, assigns(:app)
      end

      should "see someone else's app" do
        someone_else = Factory(:partner, :pending_earnings => 10000, :balance => 10000)
        not_my_app = Factory(:app, :partner => someone_else)
        get 'show', :id => not_my_app.id
        assert_response(200)
      end
    end
  end

  context "A User with apps" do
    setup do
      @user = Factory(:user)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      Factory(:app, :partner => @partner)
      Factory(:app, :partner => @partner)
      login_as(@user)
    end

    context "accessing apps index" do
      should "be shown an app they own" do
        get 'index'
        assert_response(:redirect)
        assert @partner.apps.include? assigns(:app)
      end
    end

    context "accessing app show" do
      should "be shown last app visited" do
        last_app = @partner.apps.last
        get 'show', :id => last_app.id
        assert_equal last_app, assigns(:app)
        assert_equal last_app.id, session[:last_shown_app]
        get 'index'
        assert_equal last_app, assigns(:app)
      end

      should "not see someone else's app" do
        someone_else = Factory(:partner, :pending_earnings => 10000, :balance => 10000)
        not_my_app = Factory(:app, :partner => someone_else)
        assert_raise(ActiveRecord::RecordNotFound) do
          get 'show', :id => not_my_app.id
        end
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
