require 'test_helper'

class ReportingControllerTest < ActionController::TestCase
  context "with a non-logged in user" do
    should "respond with redirect" do
      get 'index'
      assert_redirected_to(login_path(:goto => reporting_index_path))
    end
  end

  context "with a logged in user" do
    setup do
      @user = Factory(:user)
      @partner = Factory(:partner)
      @user.partners << @partner
      @app = Factory(:app)
      @partner.apps << @app
      activate_authlogic
      login_as(@user)
    end

    context "on GET to :index" do
      should "render index if there are no offers" do
        @partner.offers.delete_all
        get 'index'
        assert_response :success
        assert_template 'reporting/index'
      end

      context "with offers" do
        should "redirect to reporting path" do
          @app2 = Factory(:app)
          @partner.apps << @app2
          get :index
          assert_redirected_to(reporting_path(@app.primary_offer))
          get :index, {}, { :last_shown_app => @app2.id }
          assert_redirected_to(reporting_path(@app2.primary_offer))
          get :index, {}, { :last_shown_app => 'wah' }
          assert_redirected_to(reporting_path(@app.primary_offer))
        end
      end
    end

    context "on GET to :show" do
      should "render html" do
        UdidReports.expects(:get_available_months).with(@app.id).returns(['stuff'])
        response = get :show, :id => @app.id
        assert_response :success
        assert assigns(:udids)
        assert session[:last_shown_app] == @app.id
      end

      should "render redirect for invalid offer" do
        response = get :show, :id => 'something'
        assert_redirected_to(reporting_index_path)
        assert_equal "Unknown offer id", flash[:notice]
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

      should "render with custom parameters" do
        Appstats.any_instance.expects(:graph_data).with(:offer => @app.primary_offer, :admin => false).returns('data!')
        start_time = Time.zone.parse('2011-02-15').beginning_of_day
        end_time = Time.zone.parse('2011-02-18').end_of_day
        response = get :show, :id => @app.id, :format => 'json', :date => '2011-02-15', :end_date => '2011-02-18', :granularity => 'daily'
        appstats = assigns(:appstats)
        assert_equal start_time, appstats.start_time
        assert_equal end_time, appstats.end_time
        assert_equal :daily, appstats.granularity
      end
    end

    context "on POST to :export" do
      setup do
        @end_time = Time.parse('2011-02-15')
        @start_time = @end_time - 23.hours
        Time.zone.stubs(:now).returns(@end_time)
        Appstats.any_instance.stubs(:to_csv).returns(['a','b'])
        post :export, :id => @app.id
      end

      should respond_with_content_type :csv

      should "send a csv response" do
        assert_response :success
        assert_equal "a\nb", @response.body
        filename = eval(@response.header['Content-Disposition'].split("filename=").last)
        assert_equal filename, "#{@app.id}_#{@start_time.to_s(:yyyy_mm_dd)}_#{@end_time.to_s(:yyyy_mm_dd)}.csv"
      end

      should "assign appstats" do
        assert assigns(:appstats)
        appstats = assigns(:appstats)
        assert_equal @start_time, appstats.start_time
        assert_equal @end_time + 1.hour, appstats.end_time
        assert_equal :hourly, appstats.granularity
        assert_equal @app.id, appstats.app_key
        assert_equal "app", appstats.instance_variable_get('@stat_prefix')
        assert appstats.intervals
      end
    end

    context "on GET to :download_udids" do
      setup do
        @date = Time.zone.now.to_s(:yyyy_mm_dd)
        UdidReports.expects(:get_monthly_report).with(@app.id, @date).returns('yay,udids')
        post :download_udids, :id => @app.id, :date => @date
      end

      should respond_with_content_type :csv

      should "send a csv response" do
        assert_response :success
        assert_equal "yay,udids", @response.body
        filename = eval(@response.header['Content-Disposition'].split("filename=").last)
        assert_equal filename, "#{@app.id}_#{@date}.csv"
      end
    end

    context "on POST to :regenerate_api_key" do
      setup do
        @api_key = @user.api_key
      end

      should "regenerate api key" do
        post :regenerate_api_key
        @user.reload
        assert @user.api_key != @api_key
        assert_equal "You have successfully regenerated your API key.", flash[:notice]
        assert_redirected_to(api_reporting_path)
      end

      should "render error for invalid user" do
        @user.update_attribute(:reseller_id, 1)
        post :regenerate_api_key
        @user.reload
        assert_equal @api_key, @user.api_key
        assert_equal "Error regenerating the API key. Please try again.", flash[:error]
        assert_redirected_to(api_reporting_path)
      end
    end

    context "on GET to :aggregate" do
      should "render html" do
        get :aggregate, :format => 'html'
        assert_template 'shared/aggregate'
      end

      should "render json" do
        Appstats.any_instance.expects(:graph_data).returns('yup')
        get :aggregate, :format => 'json'
        assert assigns(:appstats)
        appstats = assigns(:appstats)

        start_time = Time.zone.now.beginning_of_hour - 23.hours
        end_time = start_time + 24.hours
        assert_equal start_time, appstats.start_time
        assert_equal end_time, appstats.end_time
        assert_equal :hourly, appstats.granularity
        assert_equal @partner.id, appstats.app_key
        assert_equal "partner", appstats.instance_variable_get('@stat_prefix')
        assert appstats.intervals

        json = JSON.parse(@response.body)
        assert_equal json['data'], 'yup'
      end
    end

    context "on POST to :export_aggregate" do
      setup do
        Appstats.any_instance.stubs(:to_csv).returns(['a','b'])
        @end_time = Time.zone.parse('2011-02-15')
        @start_time = @end_time - 23.hours
        Time.zone.stubs(:now).returns(@end_time)
        post :export_aggregate
      end

      should respond_with_content_type :csv

      should "send a csv response" do
        assert_response :success

        assert_equal "a\nb", @response.body
        filename = eval(@response.header['Content-Disposition'].split("filename=").last)
        assert_equal "all_#{@start_time.to_s(:yyyy_mm_dd)}_#{@end_time.to_s(:yyyy_mm_dd)}.csv", filename
      end

      should "assign appstats" do
        assert assigns(:appstats)
        appstats = assigns(:appstats)
        assert_equal @start_time, appstats.start_time
        assert_equal @end_time + 1.hour, appstats.end_time
        assert_equal :hourly, appstats.granularity
        assert_equal @partner.id, appstats.app_key
        assert_equal "partner", appstats.instance_variable_get('@stat_prefix')
        assert appstats.intervals
      end
    end
  end
end
