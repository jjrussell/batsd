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
        @controller.params = {:language_code => "no_such_locale" }
        @controller.send("get_locale").should be_nil
      end

      it "should get en for 'en' locale", :get_locale, :en do
        @controller.params = {:language_code => "en" }
        @controller.send("get_locale").should == :en
      end

      it "should get 'en' for 'en-US' locale", :get_locale, :en_us do
        @controller.params = {:language_code => "en-US" }
        @controller.send("get_locale").should == :en
      end

      it "should get 'zh' for 'zh' locale", :get_locale, :zh_cn do
        @controller.params = {:language_code => "zh" }
        @controller.send("get_locale").should == :"zh"
      end

      it "should get 'zh-cn' for 'zh-cn' locale", :get_locale, :zh_cn do
        @controller.params = {:language_code => "zh-cn" }
        @controller.send("get_locale").should == :"zh-cn"
      end
    end

    describe "#set_locale" do
      it "should use 'en' if params[:language_code] is not passed in", :set_locale do
        @controller.params = {}
        @controller.send("set_locale")
        I18n.locale.should == :en
      end

      it "should use 'en' if params[:language_code] is an unknown locale", :set_locale do
        @controller.params = {:language_code => "no_such_locale"}
        @controller.send("set_locale")
        I18n.locale.should == :en
      end

      it "should use 'en' if params[:language_code] is 'en'", :set_locale do
        @controller.params = {:language_code => "en"}
        @controller.send("set_locale")
        I18n.locale.should == :en
      end

      it "should use 'en' if params[:language_code] is 'en-US'", :set_locale do
        @controller.params = {:language_code => "en-US"}
        @controller.send("set_locale")
        I18n.locale.should == :en
      end

      it "should use 'zh-cn' if params[:language_code] is 'zh-cn'", :set_locale do
        @controller.params = {:language_code => "zh-cn"}
        @controller.send("set_locale")
        I18n.locale.should == :"zh-cn"
      end
    end
  end
end
