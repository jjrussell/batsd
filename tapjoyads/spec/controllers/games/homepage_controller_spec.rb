require 'spec/spec_helper'

describe Games::HomepageController do
  describe '#get_language_code' do

    before :each do
      I18n.locale = :en
    end

    after :each do
      I18n.locale = :en
      request.env["HTTP_ACCEPT_LANGUAGE"] = nil
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

    it 'Handles request strings w/o numbers' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "ko-KR, en-US"
      get(:index)
      I18n.locale.should == :ko
    end
  end

  describe "#index" do
    before :each do
      activate_authlogic
      @gamer = Factory(:gamer)
      login_as(@gamer)
      @controller.stubs(:current_gamer).returns(@gamer)
    end

    it 'creates a valid tjm_request' do
      get('index')
      tjm_request = assigns(:tjm_request)
      tjm_request.gamer_id.should == @gamer.id
    end

    context 'with a tjreferrer click as the referrer' do
      it 'records an additional tjm_request for the referral' do
        get('index', { :referrer => 'tjreferrer:abc' })
        assigns(:tjm_request)
        tjm_social_request = assigns(:tjm_social_request)
        tjm_social_request.path.should include('tjm_social_referrer')
      end
    end

    context 'with a facebook styled referrer' do
      it 'records the referral event' do
        facebook_referrer = "tj_fb_post_#{@gamer.id}"
        get('index', { :referrer => ObjectEncryptor.encrypt(facebook_referrer) })

        assigns(:tjm_request)
        tjm_social_request = assigns(:tjm_social_request)
        tjm_social_request.path.should include('tjm_social_referrer')
        tjm_social_request.social_referrer_gamer.should == @gamer.id
        tjm_social_request.social_source.should == 'fb'
        tjm_social_request.social_action.should == 'post'
      end
    end

    context 'with an old invitation styled referrer' do
      it 'records the referral event' do
        facebook_referrer = "TEST_INVITATION_ID,TEST_ADVERTISER_APP_ID"
        get('index', { :referrer => ObjectEncryptor.encrypt(facebook_referrer) })

        assigns(:tjm_request)
        tjm_social_request = assigns(:tjm_social_request)
        tjm_social_request.path.should include('tjm_social_referrer')
        tjm_social_request.social_invitation_id = 'TEST_INVITATION_ID'
        tjm_social_request.social_advertiser_app_id = 'TEST_ADVERTISER_APP_ID'
      end
    end
  end

  describe "#record_click" do
    before :each do
      activate_authlogic
      @gamer = Factory(:gamer)
      login_as(@gamer)
      @app = Factory(:app)

      @params = {
        :eid          => ObjectEncryptor.encrypt(@app.id),
        :redirect_url => ObjectEncryptor.encrypt(@app.primary_offer.url),
      }
      get('record_click', @params)
    end

    it 'records the outbound click in a tjm_request' do
      tjm_request = assigns(:tjm_request)
      tjm_request.outbound_click_url.should == @app.primary_offer.url
      tjm_request.app_id.should == @app.id
    end

    it 'redirects to the actual app url' do
      response.should be_redirect
      response.should redirect_to(@app.primary_offer.url)
    end
  end
end
