require 'test_helper'

class AgencyApi::CurrenciesControllerTest < ActionController::TestCase

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
        @response = get(:index, :agency_id => @agency_user.id, :api_key => 'foo', :app_id => @app.id)
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
        @response = get(:index, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :app_id => 'foo')
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
        @response = get(:index, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :app_id => @app2.id)
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
        Resolv.stubs(:getaddress).returns('1.1.1.1')
        @currency = Factory(:currency, :app => @app, :partner => @partner, :name => 'foo', :conversion_rate => 50, :initial_balance => 50, :test_devices => 'asdf', :callback_url => 'http://tapjoy.com', :secret_key => 'bar')
        @response = get(:index, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :app_id => @app.id)
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        expected_response = {
          'currency_id'     => @currency.id,
          'name'            => @currency.name,
          'conversion_rate' => @currency.conversion_rate,
          'initial_balance' => @currency.initial_balance,
          'test_devices'    => @currency.test_devices,
          'callback_url'    => @currency.callback_url,
          'secret_key'      => @currency.secret_key,
        }
        assert_equal [expected_response], result['currencies']
      end
    end
  end

  context "on GET to :show" do
    setup do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
      @app = Factory(:app, :partner => @partner)
      @currency = Factory(:currency, :id => @app.id, :app => @app, :partner => @partner)
    end

    context "with missing params" do
      setup do
        @response = get(:show, :id => 'not_a_currency_id')
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
        @response = get(:show, :id => @currency.id, :agency_id => @agency_user.id, :api_key => 'foo')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an invalid currency_id" do
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
    context "with an currency_id belonging to an invalid partner" do
      setup do
        @currency2 = Factory(:currency)
        @response = get(:show, :id => @currency2.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
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
        @response = get(:show, :id => @currency.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        assert_equal @currency.id, result['currency_id']
        assert_equal @currency.name, result['name']
        assert_equal @currency.conversion_rate, result['conversion_rate']
        assert_equal @currency.initial_balance, result['initial_balance']
        assert_equal @currency.test_devices, result['test_devices']
        assert_equal @currency.callback_url, result['callback_url']
        assert_equal @currency.secret_key, result['secret_key']
      end
    end
  end

  context "on POST to :create" do
    setup do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
      @app = Factory(:app, :partner => @partner)
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
        @response = post(:create, :agency_id => @agency_user.id, :api_key => 'foo', :app_id => @app.id, :name => 'currency', :conversion_rate => 100)
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
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :app_id => 'foo', :name => 'currency', :conversion_rate => 100)
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
        @partner2 = Factory(:partner)
        @app2 = Factory(:app, :partner => @partner2)
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :app_id => @app2.id, :name => 'currency', :conversion_rate => 100)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an app that already has a currency" do
      setup do
        Factory(:currency, :id => @app.id, :app => @app, :partner => @partner)
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :app_id => @app.id, :name => 'currency', :conversion_rate => 100)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with invalid params" do
      setup do
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :app_id => @app.id, :name => 'currency', :conversion_rate => -1)
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
        Resolv.stubs(:getaddress).returns('1.1.1.1')
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :app_id => @app.id, :name => 'currency', :conversion_rate => 100, :initial_balance => 100, :test_devices => 'asdf;fdsa', :callback_url => 'http://tapjoy.com', :secret_key => 'bar')
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        assert_equal @app.id, result['currency_id']
        currency = Currency.find(@app.id)
        assert_equal 'currency', currency.name
        assert_equal 100, currency.conversion_rate
        assert_equal 100, currency.initial_balance
        assert_equal 'asdf;fdsa', currency.test_devices
        assert_equal 'http://tapjoy.com', currency.callback_url
        assert_equal 'bar', currency.secret_key
      end
    end
  end

  context "on PUT to :update" do
    setup do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
      @app = Factory(:app, :partner => @partner)
      @currency = Factory(:currency, :id => @app.id, :app => @app, :partner => @partner)
    end

    context "with missing params" do
      setup do
        @response = put(:update, :id => 'not_a_currency_id')
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
        @response = put(:update, :id => @currency.id, :agency_id => @agency_user.id, :api_key => 'foo')
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
        assert result['error'].present?
      end
    end
    context "with an id belonging to an invalid partner" do
      setup do
        @currency2 = Factory(:currency)
        @response = put(:update, :id => @currency2.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
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
        @response = put(:update, :id => @currency.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :conversion_rate => -1)
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
        Resolv.stubs(:getaddress).returns('1.1.1.1')
        @response = put(:update, :id => @currency.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'foo', :conversion_rate => 200, :initial_balance => 200, :test_devices => 'asdf;fdsa', :callback_url => 'http://tapjoy.com', :secret_key => 'bar')
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        @currency.reload
        assert_equal 'foo', @currency.name
        assert_equal 200, @currency.conversion_rate
        assert_equal 200, @currency.initial_balance
        assert_equal 'asdf;fdsa', @currency.test_devices
        assert_equal 'http://tapjoy.com', @currency.callback_url
        assert_equal 'bar', @currency.secret_key
      end
    end
  end

end
