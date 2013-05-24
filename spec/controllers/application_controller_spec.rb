require 'spec_helper'

describe ApplicationController do
  describe '#generate_web_request' do
    it "should create a new web request" do
      @controller.stub(:geoip_data).and_return({ :continent => "NA", :region => "West", :city => "San Francisco",
                                                :lat => 38.0, :long => 97.0, :postal_code => "94109",
                                                :area_code => 415, :dma_code => 807 })
      @controller.send("generate_web_request").geoip_postal_code.should == "94109"
      @controller.send("generate_web_request").geoip_city.should == "San Francisco"
      @controller.send("generate_web_request").geoip_dma_code.should == 807
      @controller.send("generate_web_request").geoip_area_code.should == 415
      @controller.send("generate_web_request").geoip_continent.should == "NA"
    end
  end

  describe '#verify_params' do
    before :each do
      @controller.params = { :hello => "yo", :hi => "sup" }
    end

    context 'with missing parameters' do
      it 'should return false with an array of arguments' do
        @controller.send(:verify_params, :hello, :hi, :bye, :render_missing_text => false).should be_false
      end

      it 'should return false with an array as its first argument' do
        @controller.send(:verify_params, [:hello, :hi, :bye], :render_missing_text => false).should be_false
      end
    end

    context 'with all parameters existing' do
      it 'should return true with an array of arguments' do
        @controller.send(:verify_params, :hello, :hi, :render_missing_text => false).should be_true
      end

      it 'should return true with an array as its first argument' do
        @controller.send(:verify_params, [:hello, :hi], :render_missing_text => false).should be_true
      end
    end
  end

  describe '#verify_records' do
    context 'with records not existing' do
      it 'should return false with an array of arguments' do
        @controller.send(:verify_records, "thing1", "thing2", nil, :render_missing_text => false).should be_false
      end

      it 'should return false with an array as its first argument' do
        @controller.send(:verify_records, ["thing1", "thing2", nil], :render_missing_text => false).should be_false
      end
    end

    context 'with all records existing' do
      it 'should return true with an array of arguments' do
        @controller.send(:verify_records, "thing1", "thing2", :render_missing_text => false).should be_true
      end

      it 'should return false with an array as its first argument' do
        @controller.send(:verify_records, ["thing1", "thing2"], :render_missing_text => false).should be_true
      end
    end
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
