require 'spec/spec_helper'

describe Games::HomepageController do
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
end
