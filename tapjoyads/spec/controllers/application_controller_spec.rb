require 'spec_helper'

describe ApplicationController do
  context "locale" do
    before :each do
      @controller = ApplicationController.new
    end

    describe '#get_locale' do
      it "should get nil if params[:language_code] is not set", :get_locale, :nil do
        @controller.params = {}
        @controller.send("get_locale").should be_nil
      end

      it "should get nil if params[:language_code] is an unknown locale", :get_locale, :no_such_locale do
        @controller.params = {:language_code => "no_such_locale", :country_code => 'US' }
        @controller.send("get_locale").should be_nil
      end

      it "should get en for 'en' locale", :get_locale, :en do
        @controller.params = {:language_code => "en", :country_code => 'US' }
        @controller.send("get_locale").should == :en
      end

      it "should get 'en' for 'en-US' locale", :get_locale, :en_us do
        @controller.params = {:language_code => "en-US", :country_code => 'US' }
        @controller.send("get_locale").should == :en
      end

      it "should get 'zh' for 'zh' locale", :get_locale, :zh_cn do
        @controller.params = {:language_code => "zh", :country_code => 'CN' }
        @controller.send("get_locale").should == :"zh-cn"
      end

      it "should get 'zh-cn' for 'zh-cn' locale", :get_locale, :zh_cn do
        @controller.params = {:language_code => "zh-cn", :country_code => 'CN' }
        @controller.send("get_locale").should == :"zh-cn"
      end
    end

    describe "#set_locale" do
      it "should use 'en' if params[:language_code] is not passed in", :set_locale do
        @controller.params = {}
        @controller.send("set_locale")
        I18n.locale.should == :en
      end

      it "should use 'en' if params[:language_code] is an empty string", :set_locale do
        @controller.params = {:language_code => '', :country_code => 'US'}
        @controller.send("set_locale")
        I18n.locale.should == :en
      end

      it "should use 'en' if params[:language_code] is an unknown locale", :set_locale do
        @controller.params = {:language_code => "no_such_locale", :country_code => 'US'}
        @controller.send("set_locale")
        I18n.locale.should == :en
      end

      it "should use 'en' if params[:language_code] is 'en'", :set_locale do
        @controller.params = {:language_code => "en", :country_code => 'US'}
        @controller.send("set_locale")
        I18n.locale.should == :en
      end

      it "should use 'en' if params[:language_code] is 'en-US'", :set_locale do
        @controller.params = {:language_code => "en-US", :country_code => 'US'}
        @controller.send("set_locale")
        I18n.locale.should == :en
      end

      it "should use 'zh-cn' if params[:language_code] is 'zh-cn'", :zh, :set_locale do
        @controller.params = {:language_code => "zh-cn", :country_code => 'CN'}
        @controller.send("set_locale")
        I18n.locale.should == :"zh-cn"
      end

      it "should use 'zh-cn' if language_code='zh' and country_code=CN", :zh, :set_locale do
        @controller.params = {:language_code => "zh", :country_code => 'CN'}
        @controller.send("set_locale")
        I18n.locale.should == :"zh-cn"
      end

      it "should use 'zh-cn' if language_code='zh-Hans' and country_code=CN", :zh, :set_locale do
        @controller.params = {:language_code => "zh-Hans", :country_code => 'CN'}
        @controller.send("set_locale")
        I18n.locale.should == :"zh-cn"
      end

      it "should use 'zh' if language_code='zh' and country_code=unknown", :de, :set_locale do
        @controller.params = {:language_code => "zh", :country_code => 'unknown'}
        @controller.send("set_locale")
        I18n.locale.should == :zh
      end

      it "should use 'zh' if language_code='zh-unknown' and country_code=no_country", :de, :set_locale do
        @controller.params = {:language_code => "zh-unknown", :country_code => 'no_country'}
        @controller.send("set_locale")
        I18n.locale.should == :zh
      end

      it "should use 'de' if language_code='' and country_code=de", :de, :set_locale do
        @controller.params = {:language_code => "", :country_code => 'DE'}
        @controller.send("set_locale")
        I18n.locale.should == :de
      end

      it "should use 'de' if language_code='de' and country_code=fr", :de, :set_locale do
        @controller.params = {:language_code => "de", :country_code => 'DE'}
        @controller.send("set_locale")
        I18n.locale.should == :de
      end
    end
  end
end
