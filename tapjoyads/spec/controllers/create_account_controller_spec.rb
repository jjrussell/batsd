require 'spec/spec_helper'

describe CreateAccountController do
  describe "on GET to :index" do
    before :each do
      @agency_user = Factory(:agency_user)
      @email_address = Factory.next(:email)
      @app_name = Factory.next(:name)
      @password = Factory.next(:guid)
      @valid_params = {
        :agency_id => @agency_user.id,
        :app_name => @app_name,
        :email => @email_address,
        :password => @password,
      }
    end

    it "should detect missing required params" do
      expected_errors = { :error => "missing required parameters" }

      get :index

      response.should be_success
      response.content_type.should =~ /json/
      response.body.should == expected_errors.to_json
    end

    it 'should detect invalid agency_id' do
      invalid_params = {
        :agency_id => 'foo',
        :app_name => 'foo',
        :email => 'foo',
        :password => 'foo'
      }
      expected_errors = { :error => "unknown or invalid agency_id" }

      get :index, @valid_params.merge(invalid_params)

      response.should be_success
      response.content_type.should =~ /json/
      response.body.should == expected_errors.to_json
    end

    it 'should detect invalid email address' do
      invalid_params = {
        :app_name => 'foo',
        :email => 'foo',
        :password => 'foobaz'
      }
      expected_errors = {
        :error => [
          [ :email, 'is too short (minimum is 6 characters)' ],
          [ :email, 'should look like an email address.' ]
        ]
      }

      get :index, @valid_params.merge(invalid_params)

      response.should be_success
      response.content_type.should =~ /json/
      response.body.should == expected_errors.to_json
    end

    it 'should detect existing email address' do
      invalid_params = {
        :email => @agency_user.email,
      }
      expected_errors = {
        :error => [
          [ :email, 'has already been taken' ],
          [ :username, 'has already been taken' ]
        ]
      }

      get :index, @valid_params.merge(invalid_params)

      response.should be_success
      response.content_type.should =~ /json/
      response.body.should == expected_errors.to_json
    end

    it 'should detect invalid password' do
      invalid_params = {
        :password => 'foo'
      }
      expected_errors = {
        :error => [
          [ :password, 'is too short (minimum is 4 characters)' ],
          [ :password_confirmation, 'is too short (minimum is 4 characters)' ]
        ]
      }

      get :index, @valid_params.merge(invalid_params)

      response.should be_success
      response.content_type.should =~ /json/
      response.body.should == expected_errors.to_json
    end

    it 'should create valid user/partner' do
      get :index, @valid_params

      app = App.find_by_name(@app_name)
      app.should_not be_nil

      user = User.find_by_email(@email_address)
      user.should_not be_nil

      partner = Partner.find_by_name(@email_address)
      partner.should_not be_nil

      user.partners.map(&:id).should == [ partner.id ]
      @agency_user.partners.map(&:id).should == [ partner.id ]

      response.should be_success
      response.content_type.should =~ /json/
      response.body.should == { :app_id => app.id }.to_json
    end
  end
end
