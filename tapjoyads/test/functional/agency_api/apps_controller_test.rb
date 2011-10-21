require 'test_helper'

class AgencyApi::AppsControllerTest < ActionController::TestCase

  context "on GET to :index" do
    setup do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
      @app = Factory(:app, :partner => @partner)
    end

    context "with missing params" do
      setup do
        @response = get(:index)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad credentials" do
      setup do
        @response = get(:index, :agency_id => @agency_user.id, :api_key => 'foo', :partner_id => @partner.id)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an invalid partner_id" do
      setup do
        @partner2 = Factory(:partner)
        @response = get(:index, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :partner_id => @partner2.id)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with valid params" do
      setup do
        @response = get(:index, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :partner_id => @partner.id)
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        assert_equal [{ 'app_id' => @app.id, 'name' => @app.name, 'platform' => @app.platform, 'store_id' => @app.store_id }], result['apps']
      end
    end
  end

  context "on GET to :show" do
    setup do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
      @app = Factory(:app, :partner => @partner)
    end

    context "with missing params" do
      setup do
        @response = get(:show, :id => 'not_an_app_id')
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad credentials" do
      setup do
        @response = get(:show, :id => @app.id, :agency_id => @agency_user.id, :api_key => 'foo')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an invalid app_id" do
      setup do
        @response = get(:show, :id => 'foo', :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an app_id belonging to an invalid partner" do
      setup do
        @app2 = Factory(:app)
        @response = get(:show, :id => @app2.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with valid params" do
      setup do
        @response = get(:show, :id => @app.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        assert_equal @app.id, result['app_id']
        assert_equal @app.name, result['name']
        assert_equal @app.platform, result['platform']
        assert_equal @app.store_id, result['store_id']
        assert_equal @app.secret_key, result['app_secret_key']
        assert_equal @app.primary_offer.integrated?, result['integrated']
        assert !result['integrated']
      end
    end
  end

  context "on POST to :create" do
    setup do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
    end

    context "with missing params" do
      setup do
        @response = post(:create)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad credentials" do
      setup do
        @response = post(:create, :agency_id => @agency_user.id, :api_key => 'foo', :partner_id => @partner.id, :name => 'app', :platform => 'iphone')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an invalid partner_id" do
      setup do
        @partner2 = Factory(:partner)
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :partner_id => @partner2.id, :name => 'app', :platform => 'iphone')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with invalid params" do
      setup do
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :partner_id => @partner.id, :name => 'app', :platform => 'foo')
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with valid params" do
      setup do
        @params = { :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :partner_id => @partner.id, :name => 'app', :platform => 'iphone' }
        @response = post(:create, @params)
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        assert_equal 1, @partner.apps.count
        app = @partner.apps.first
        assert_equal app.id, result['app_id']
        assert_equal app.secret_key, result['app_secret_key']
        assert_equal app.store_id, nil
      end

      should "assign store id" do
        Sqs.expects(:send_message).with('test_GetStoreInfo', regexp_matches(/(\w+-){4}\w+/))
        post :create, @params.merge(:store_id => 'wah!')
        result = JSON.parse(@response.body)
        assert result['success']
        app = App.find(result['app_id'])
        assert_equal app.store_id, 'wah!'
      end

      should "save activity logs" do
        controller.expects :log_activity
        controller.expects :save_activity_logs
        post :create, @params
      end
    end
  end

  context "on PUT to :update" do
    setup do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
      @app = Factory(:app, :partner => @partner)
    end

    context "with missing params" do
      setup do
        @response = put(:update, :id => 'not_an_app_id')
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad credentials" do
      setup do
        @response = put(:update, :id => @app.id, :agency_id => @agency_user.id, :api_key => 'foo')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an invalid id" do
      setup do
        @response = put(:update, :id => 'foo', :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert_equal result['error'], "app not found"
      end
    end
    context "with an id belonging to an invalid partner" do
      setup do
        @app2 = Factory(:app)
        @response = put(:update, :id => @app2.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with invalid app" do
      setup do
        @app.platform = 'pizza'
        @app.send(:update_without_callbacks)
        @response = put(:update, :id => @app.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert_equal result['error'].join(' '), 'platform is not included in the list'
      end
    end
    context "with valid params" do
      setup do
        @params = {:id => @app.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'foo'}
        @response = put(:update, @params)
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        assert_equal 1, @partner.apps.count
        app = @partner.apps.first
        assert_equal 'foo', app.name
      end

      should "save activity logs" do
        controller.expects :log_activity
        controller.expects :save_activity_logs
        post :update, @params
      end

      should "change store id" do
        Sqs.expects(:send_message).with('test_GetStoreInfo', regexp_matches(/(\w+-){4}\w+/))
        post :update, @params.merge(:store_id => 'wah!')
        result = JSON.parse(@response.body)
        assert result['success']
        @app.reload
        assert_equal @app.store_id, 'wah!'
      end
    end
  end

end
