require 'spec/spec_helper'

describe AgencyApi::CurrenciesController do
  before :each do
    fake_the_web
    @agency_user = Factory(:agency_user)
    @partner = Factory(:partner)
    @agency_user.partners << @partner
    @app = Factory(:app, :partner => @partner)
  end

  describe '#index' do
    before :each do
      @valid_params = {
        :agency_id => @agency_user.id,
        :api_key => @agency_user.api_key,
        :app_id => @app.id
      }
    end

    it 'responds with error given missing params' do
      get(:index)

      should_respond_with_json_error(400)
    end

    it 'responds with error given bad credentials' do
      get(:index, @valid_params.merge(:api_key => 'foo'))

      should_respond_with_json_error(403)
    end

    it 'responds with error given invalid app_id' do
      get(:index, @valid_params.merge(:app_id => 'foo'))

      should_respond_with_json_error(400)
    end

    it 'responds with error given app_id from invalid partner' do
      app2 = Factory(:app)
      get(:index, @valid_params.merge(:app_id => app2.id))

      should_respond_with_json_error(403)
    end

    it 'responds with success given valid params' do
      currency = Factory(:currency,
        :app => @app,
        :partner => @partner,
        :name => 'foo',
        :conversion_rate => 50,
        :initial_balance => 50,
        :test_devices => 'asdf',
        :callback_url => 'http://tapjoy.com',
        :secret_key => 'bar')

      get(:index, @valid_params)

      should_respond_with_json_success(200)

      expected_response = {
        'currency_id'     => currency.id,
        'name'            => currency.name,
        'conversion_rate' => currency.conversion_rate,
        'initial_balance' => currency.initial_balance,
        'test_devices'    => currency.test_devices,
        'callback_url'    => currency.callback_url,
        'secret_key'      => currency.secret_key,
      }

      result = JSON.parse(response.body)
      result['currencies'].should == [expected_response]
    end
  end

  describe '#show' do
    before :each do
      @currency = Factory(:currency,
        :id => @app.id,
        :app => @app,
        :partner => @partner)

      @valid_params = {
        :id => @currency.id,
        :agency_id => @agency_user.id,
        :api_key => @agency_user.api_key
      }
    end

    it 'responds with error given missing params' do
      get(:show)

      should_respond_with_json_error(400)
    end

    it 'responds with error given bad credentials' do
      get(:show, @valid_params.merge(:api_key => 'foo'))

      should_respond_with_json_error(403)
    end

    it 'responds with error given invalid currency_id' do
      get(:show, @valid_params.merge(:id => 'foo'))

      should_respond_with_json_error(400)
    end

    it 'responds with error given currency_id from an invalid partner' do
      currency2 = Factory(:currency)

      get(:show, @valid_params.merge(:id => currency2.id))

      should_respond_with_json_error(403)
    end

    it 'responds with success given valid params' do
      get(:show, @valid_params)

      should_respond_with_json_success(200)

      result = JSON.parse(response.body)
      result['currency_id'].should == @currency.id
      result['name'].should == @currency.name
      result['conversion_rate'].should == @currency.conversion_rate
      result['initial_balance'].should == @currency.initial_balance
      result['test_devices'].should == @currency.test_devices
      result['callback_url'].should == @currency.callback_url
      result['secret_key'].should == @currency.secret_key
    end
  end

  describe '#create' do
    before :each do
      @valid_params = {
        :agency_id => @agency_user.id,
        :api_key => @agency_user.api_key,
        :app_id => @app.id,
        :name => 'currency',
        :conversion_rate => 100,
        :initial_balance => 100,
        :test_devices => 'asdf;fdsa',
        :callback_url => 'http://tapjoy.com',
        :secret_key => 'bar'
      }
    end

    it 'responds with error given missing params' do
      post(:create)

      should_respond_with_json_error(400)
    end

    it 'responds with error given bad credentials' do
      post(:create, @valid_params.merge(:api_key => 'foo'))

      should_respond_with_json_error(403)
    end

    it 'responds with error given invalid app_id' do
      post(:create, @valid_params.merge(:app_id => 'foo'))

      should_respond_with_json_error(400)
    end

    it 'responds with error given app_id from an invalid partner' do
      partner2 = Factory(:partner)
      app2 = Factory(:app, :partner => partner2)
      post(:create, @valid_params.merge(:app_id => app2.id))

      should_respond_with_json_error(403)
    end

    it 'responds with error when an app already has a currency' do
      Factory(:currency, :id => @app.id, :app => @app, :partner => @partner)

      post(:create, @valid_params)

      should_respond_with_json_error(400)
    end

    it 'responds with error given an invalid conversion rate' do
      post(:create, @valid_params.merge(:conversion_rate => -1))

      should_respond_with_json_error(400)
    end

    it 'responds with success given valid params' do
      post(:create, @valid_params)

      should_respond_with_json_success(200)

      result = JSON.parse(response.body)
      result['currency_id'].should == @app.id
      currency = Currency.find(@app.id)
      currency.name.should == 'currency'
      currency.conversion_rate.should == 100
      currency.initial_balance.should == 100
      currency.test_devices.should == 'asdf;fdsa'
      currency.callback_url.should == 'http://tapjoy.com'
      currency.secret_key.should == 'bar'
    end
  end

  describe '#update' do
    before :each do
      @currency = Factory(:currency,
        :id => @app.id,
        :app => @app,
        :partner => @partner)

      @valid_params = {
        :id => @currency.id,
        :agency_id => @agency_user.id,
        :api_key => @agency_user.api_key,
        :name => 'foo',
        :conversion_rate => 200,
        :initial_balance => 200,
        :test_devices => 'asdf;fdsa',
        :callback_url => 'http://tapjoy.com',
        :secret_key => 'bar'
      }
    end

    it 'responds with error given missing params' do
      put(:update)

      should_respond_with_json_error(400)
    end

    it 'responds with error given bad credentials' do
      put(:update, @valid_params.merge(:api_key => 'foo'))

      should_respond_with_json_error(403)
    end

    it 'responds with error given invalid id' do
      put(:update, @valid_params.merge(:id => 'foo'))

      should_respond_with_json_error(400)
    end

    it 'responds with error given id from an invalid partner' do
      currency2 = Factory(:currency)

      put(:update, @valid_params.merge(:id => currency2.id))

      should_respond_with_json_error(403)
    end

    it 'responds with error given an invalid conversion rate' do
      put(:update, @valid_params.merge(:conversion_rate => -1))

      should_respond_with_json_error(400)
    end

    it 'responds with success given valid params' do
      put(:update, @valid_params)

      should_respond_with_json_success(200)

      @currency.reload
      @currency.name.should == 'foo'
      @currency.conversion_rate.should == 200
      @currency.initial_balance.should == 200
      @currency.test_devices.should == 'asdf;fdsa'
      @currency.callback_url.should == 'http://tapjoy.com'
      @currency.secret_key.should == 'bar'
    end
  end
end
