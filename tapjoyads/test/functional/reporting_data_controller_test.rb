require 'test_helper'

class ReportingDataControllerTest < ActionController::TestCase
  context "on GET to :index" do
    setup do
      @partner = Factory(:partner)
      @user = Factory(:user)
    end

    context "with missing params" do
      setup do
        @response = get(:index)
      end

      should respond_with(400)
    end

    context "with bad credentials" do
      setup do
        @response = get(:index, :date => "2011-02-15", :username => @user.username, :api_key => 'poo')
      end
      should respond_with(403)
    end

    context "with valid params, xml" do
      setup do
        @response = get(:index, :date => "2011-02-15", :username => @user.username, :api_key => @user.api_key)
      end
      should respond_with(200)
      should respond_with_content_type(:xml)
    end

    context "with valid params, json" do
      setup do
        @response = get(:index, :format => 'json', :date => "2011-02-15", :username => @user.username, :api_key => @user.api_key)
      end
      should respond_with(200)
      should respond_with_content_type(:json)
    end
  end

  context "on GET to :udids with data" do
    setup do
      @partner = Factory(:partner)
      @user = Factory(:user)
      @partner.users << @user
      @offer = Factory(:app).primary_offer
      @partner.offers << @offer
      UdidReports.stubs(:get_daily_report).returns('a,b,c')
      UdidReports.stubs(:get_monthly_report).returns('a,b,c')
    end

    context "with missing params" do
      setup do
        @response = get(:udids)
      end

      should respond_with(400)
    end

    context "with invalid date parameter" do
      setup do
        @response = get(:udids, :offer_id => @offer.id, :date => "201-02-15", :username => @user.username, :api_key => @user.api_key)
      end
      should respond_with(404)
      should "return an error message" do
        assert_equal @response.body, "Invalid date"
      end
    end

    context "with invalid offer" do
      setup do
        @response = get(:udids, :offer_id => 'poo', :date => "201-02-15", :username => @user.username, :api_key => @user.api_key)
      end
      should respond_with(404)
      should "return an error message" do
        assert_equal @response.body, "Unknown offer id"
      end
    end

    context "daily with valid params" do
      setup do
        @response = get(:udids, :offer_id => @offer.id, :date => "2011-02-15", :username => @user.username, :api_key => @user.api_key)
      end
      should respond_with(200)
      should respond_with_content_type(:csv)
      should "return a csv object" do
        filename = eval(@response.header['Content-Disposition'].split("filename=").last)
        assert_equal filename, "#{@offer.id}_2011-02-15.csv"
        assert_equal @response.body, 'a,b,c'
      end
    end

    context "monthly with valid params" do
      setup do
        @response = get(:udids, :offer_id => @offer.id, :date => "2011-02", :username => @user.username, :api_key => @user.api_key)
      end
      should respond_with(200)
      should respond_with_content_type(:csv)
      should "return a csv object" do
        filename = eval(@response.header['Content-Disposition'].split("filename=").last)
        assert_equal filename, "#{@offer.id}_2011-02.csv"
        assert_equal @response.body, 'a,b,c'
      end
    end
  end

  context "on GET to :udids without data" do
    setup do
      @partner = Factory(:partner)
      @user = Factory(:user)
      @partner.users << @user
      @offer = Factory(:app).primary_offer
      @partner.offers << @offer
    end

    context "with missing params" do
      setup do
        @response = get(:udids)
      end

      should respond_with(400)
    end

    context "daily with valid params" do
      setup do
        @response = get(:udids, :offer_id => @offer.id, :date => "2011-02-15", :username => @user.username, :api_key => @user.api_key)
      end
      should respond_with(404)
      should respond_with_content_type(:html)
      should "have error message" do
        assert_equal @response.body, "No UDID report exists for this date"
      end
    end

    context "monthly with valid params" do
      setup do
        @response = get(:udids, :offer_id => @offer.id, :date => "2011-02", :username => @user.username, :api_key => @user.api_key)
      end
      should respond_with(404)
      should respond_with_content_type(:html)
      should "have error message" do
        assert_equal @response.body, "No UDID report exists for this date"
      end
    end
  end
end
