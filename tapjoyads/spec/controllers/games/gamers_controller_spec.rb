require 'spec/spec_helper'

describe Games::GamersController do
  before :each do
    activate_authlogic
  end

  describe '#get_language_code' do
    before :each do 
      I18n.locale = :en
    end
    it 'sets locale based on language code' do
      get :index, :language_code => "zh"
      I18n.locale.should == :zh
    end
    it 'sets locale based on HTTP_ACCEPT_LANGUAGE' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "zh"
      get :index
      I18n.locale.should == :zh
    end
    it 'overrides HTTP_ACCEPT_LANGUAGE with language code' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "en"
      get :index, :language_code => "zh"
      I18n.locale.should == :zh
    end
    it 'sets default_locale when language_code values are unacceptable' do
      get :index, :language_code => "honey badger don't care about locale"
      I18n.locale.should == I18n.default_locale
    end
    it 'sets default_locale when HTTP_ACCEPT_LANGUAGE values are unacceptable' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "fake,notreal;7;totallyInvalidInput"
      get :index
      I18n.locale.should == I18n.default_locale
    end
    it 'sets language_code when HTTP_ACCEPT_LANGUAGE values are unacceptable' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "fake,notreal;7;totallyInvalidInput"
      get :index, :language_code => "zh"
      I18n.locale.should == :zh   
    end
    it 'sets the highest available locale in HTTP_ACCEPT_LANGUAGE' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "invalid,es;q=0.5,zh;q=0.9"
      get :index
      I18n.locale.should == :zh   
    end
  end
  
  describe 'create' do
    before :each do
      @date = 13.years.ago(Time.zone.now.beginning_of_day) - 1.day
      @options = {
        :gamer => {
          :email            => Factory.next(:email),
          :password         => Factory.next(:name),
          :terms_of_service => '1',
        },
        :date => {
          :year  => @date.year,
          :month => @date.month,
          :day   => @date.day,
        },
        :default_platforms => {
          :android => '1',
          :ios => '0',
        }
      }
    end

    it 'should create a new gamer' do
      Sqs.expects(:send_message).once
      post 'create', @options

      should_respond_with_json_success(200)
    end

    it 'should reject when under 13 years old' do
      @date += 2.days
      @options[:date] = {
        :year  => @date.year,
        :month => @date.month,
        :day   => @date.day,
      }
      post 'create', @options

      should_respond_with_json_error(403)
    end

    it 'should reject when under date is invalid' do
      @options[:date] = {
        :year  => @date.year,
        :month => 11,
        :day   => 31,
      }
      post 'create', @options

      should_respond_with_json_error(403)
    end
  end

  describe 'Destroy' do
    before :each do
      @gamer = Factory(:gamer)
      @controller.stubs(:current_gamer).returns(@gamer)
    end

    it 'should display confirmation page' do
      get 'confirm_delete'
      response.should be_success
    end

    it 'should deactivate gamer' do
      delete 'destroy'

      response.should be_redirect
      (Time.zone.now - @gamer.deactivated_at).should < 60
    end
  end
end
