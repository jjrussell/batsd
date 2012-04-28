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
      get(:index, :language_code => "de")
      I18n.locale.should == :de
    end

    it 'checks prefix of provided language code' do
      get(:index, :language_code => "en-XX")
      I18n.locale.should == :en
    end

    it 'sets locale based on HTTP_ACCEPT_LANGUAGE' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "de"
      get(:index)
      I18n.locale.should == :de
    end

    it 'sets more locale based on HTTP_ACCEPT_LANGUAGE, and ignores suffix casing' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "zh-CN"
      get(:index)
      I18n.locale.should == :"zh-cn"
      request.env["HTTP_ACCEPT_LANGUAGE"] = "zh-sg"
      get(:index)
      I18n.locale.should == :"zh-sg"
    end

    it 'sets more locale based on language_code, and ignores suffix casing' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "fake,notreal;7;totallyInvalidInput!"
      get(:index, :language_code => "zh-cn")
      I18n.locale.should == :"zh-cn"
      get(:index, :language_code => "zh-SG")
      I18n.locale.should == :"zh-sg"
    end

    it 'attempts to split locale based on HTTP_ACCEPT_LANGUAGE' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "ko-KR,es;q=0.5,zh;q=0.9"
      get(:index)
      I18n.locale.should == :ko
    end

    it 'overrides HTTP_ACCEPT_LANGUAGE with language code' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "en"
      get(:index, :language_code => "de")
      I18n.locale.should == :de
    end

    it 'sets default_locale when language_code values are invalid' do
      get(:index, :language_code => "honey badger don't care about locale")
      I18n.locale.should == I18n.default_locale
    end

    it 'sets HTTP_ACCEPT_LANGUAGE when language_code values are invalid' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "de"
      get(:index, :language_code => "honey badger don't care about locale")
      I18n.locale.should == :de
    end

    it 'sets default_locale when HTTP_ACCEPT_LANGUAGE values are unacceptable' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "fake,notreal;7;totallyInvalidInput"
      get(:index)
      I18n.locale.should == I18n.default_locale
    end

    it 'sets language_code when HTTP_ACCEPT_LANGUAGE values are unacceptable' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "fake,notreal;7;totallyInvalidInput!"
      get(:index, :language_code => "de")
      I18n.locale.should == :de
    end

    it 'sets the highest available locale in HTTP_ACCEPT_LANGUAGE' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "invalid,es;q=0.5,de;q=0.9"
      get(:index)
      I18n.locale.should == :de
    end

    it 'Handles request strings w/o numbers' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "ko-KR, en-US"
      get(:index)
      I18n.locale.should == :ko
    end
  end
end
