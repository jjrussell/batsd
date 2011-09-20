require 'test_helper'

class ReportingControllerTest < ActionController::TestCase
  context "on GET to :index" do
    should "respond with redirect for non-logged in user" do
      get 'index'
      assert_response(:redirect)
    end

    context "with a logged in user" do
      setup do
        activate_authlogic
        user = Factory(:user)
        partner = Factory(:partner)
        user.partners << partner
        login_as(user)
        get 'index'
      end

      should "render index if there are no offers" do
        assert_response :success
        assert_template 'reporting/index'
      end
    end

    context "with a logged in user with offers" do
      setup do
        activate_authlogic
        user = Factory(:user)
        partner = Factory(:partner)
        user.partners << partner
        login_as(user)
        @app1 = Factory(:app)
        @app2 = Factory(:app)
        partner.apps << @app1
        partner.apps << @app2
      end

      should "redirect to reporting path" do
        get :index
        assert_redirected_to(reporting_path(@app1.primary_offer))
        get :index, {}, { :last_shown_app => @app2.id }
        assert_redirected_to(reporting_path(@app2.primary_offer))
        get :index, {}, { :last_shown_app => 'wah' }
        assert_redirected_to(reporting_path(@app1.primary_offer))
      end
    end
  end

  context "on GET to :show" do
    setup do
      activate_authlogic
      user = Factory(:user)
      login_as(user)
      @partner = Factory(:partner)
      user.partners << @partner
      @app = Factory(:app)
      @partner.apps << @app
    end

    should "render html" do
      UdidReports.expects(:get_available_months).with(@app.id).returns(['stuff'])
      response = get :show, :id => @app.id
      assert_response :success
      assert assigns(:udids)
      assert session[:last_shown_app] == @app.id
    end

    should "not change last_shown_app if offer isn't app" do
      video_offer = Factory(:video_offer)
      primary_offer = Offer.new(:item => video_offer)
      @partner.offers << primary_offer
      get :show, :id => @app.id
      get :show, :id => video_offer.id
      assert_equal session[:last_shown_app], @app.id
    end

    should "render json" do
      Appstats.any_instance.expects(:graph_data).with(:offer => @app.primary_offer, :admin => false).returns('data!')
      response = get :show, :id => @app.id, :format => 'json'
      assert_response :success
      assert JSON.parse(response.body)['data']
    end

  end

  context "on POST to :export" do

  end

  context "on GET to :api" do

  end

  context "on GET to :download_udids" do

  end

  context "on POST to :regenerate_api_key" do

  end

  context "on GET to :aggregate" do

  end

  context "on POST to :export_aggregate" do

  end
end
