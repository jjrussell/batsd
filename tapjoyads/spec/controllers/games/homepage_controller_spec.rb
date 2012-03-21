require 'spec/spec_helper'

describe Games::HomepageController do
  before :each do
    fake_the_web
    activate_authlogic
    @gamer = Factory(:gamer)
    @controller.stubs(:current_gamer).returns(@gamer)
  end

  describe '#get_language_code' do

    before :each do
      I18n.locale = :en
    end

    it 'sets locale based on language code' do
      get(:index, :language_code => "zh")
      I18n.locale.should == :zh
    end

    it 'checks prefix of provided language code' do
      get(:index, :language_code => "en-XX")
      I18n.locale.should == :en
    end

    it 'sets locale based on HTTP_ACCEPT_LANGUAGE' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "zh"
      get(:index)
      I18n.locale.should == :zh
    end

    it 'attempts to split locale based on HTTP_ACCEPT_LANGUAGE' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "ko-KR,es;q=0.5,zh;q=0.9"
      get(:index)
      I18n.locale.should == :ko
    end

    it 'overrides HTTP_ACCEPT_LANGUAGE with language code' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "en"
      get(:index, :language_code => "zh")
      I18n.locale.should == :zh
    end

    it 'sets default_locale when language_code values are invalid' do
      get(:index, :language_code => "honey badger don't care about locale")
      I18n.locale.should == I18n.default_locale
    end

    it 'sets HTTP_ACCEPT_LANGUAGE when language_code values are invalid' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "zh"
      get(:index, :language_code => "honey badger don't care about locale")
      I18n.locale.should == :zh
    end

    it 'sets default_locale when HTTP_ACCEPT_LANGUAGE values are unacceptable' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "fake,notreal;7;totallyInvalidInput"
      get(:index)
      I18n.locale.should == I18n.default_locale
    end

    it 'sets language_code when HTTP_ACCEPT_LANGUAGE values are unacceptable' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "fake,notreal;7;totallyInvalidInput!"
      get(:index, :language_code => "zh")
      I18n.locale.should == :zh
    end

    it 'sets the highest available locale in HTTP_ACCEPT_LANGUAGE' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "invalid,es;q=0.5,zh;q=0.9"
      get(:index)
      I18n.locale.should == :zh
    end

  end

  describe '#record_local_request' do
    it 'logs the path' do
      @params = { :request_path => games_logout_path }
      get(:record_local_request, @params)
      response.response_code.should == 200
      tjm_request = assigns(:tjm_request)
      tjm_request.path.should include('tjm_games/gamer_sessions_destroy')
      tjm_request.controller.should == 'games/gamer_sessions'
      tjm_request.action.should == 'destroy'
    end

    it 'logs from supplied controller/action' do
      @params = { :request_controller => 'test_controller', :request_action => 'test_action' }
      get(:record_local_request, @params)
      response.response_code.should == 200
      tjm_request = assigns(:tjm_request)
      tjm_request.path.should include('tjm_test_controller_test_action')
      tjm_request.controller.should == 'test_controller'
      tjm_request.action.should == 'test_action'
    end

    context 'with no arguments' do
      it 'return an error' do
        @params = {}
        get(:record_local_request, @params)
        should_respond_with_json_error(400)
      end
    end

    context 'with invalid arguments' do
      it 'returns an error' do
        @params = { :request_path => '/test_invalid'}
        get(:record_local_request, @params)
        should_respond_with_json_error(400)
      end
    end
  end
end
