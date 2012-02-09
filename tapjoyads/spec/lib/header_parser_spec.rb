require 'spec_helper'

describe HeaderParser do
  context "The HeaderParser" do
    before :each do
      @user_agents = {
        :itouch       => 'Mozilla/5.0 (iPod; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5',
        :iphone_ios_4 => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_5 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8L1 Safari/6533.18.5',
        :iphone_ios_5 => 'Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3',
        :ipad_ios_4   => 'Mozilla/5.0 (iPad; U; CPU OS 4_3_5 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8L1 Safari/6533.18.5',
        :ipad_ios_5   => 'Mozilla/5.0 (iPad; CPU OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3',
        :nexus_one    => 'Mozilla/5.0 (Linux; U; Android 2.3.4; en-us; Nexus One Build/GRJ22) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1',
        :evo          => 'Mozilla/5.0 (Linux; U; Android 2.2; en-us; Sprint APA9292KT Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1',
        :galaxy_tab   => 'Mozilla/5.0 (Linux; U; Android 3.1; en-us; GT-P7510 Build/HMJ37) AppleWebKit/534.13 (KHTML, like Gecko) Version/4.0 Safari/534.13',
      }
    end

    it "parses os_version from known user-agents" do
      HeaderParser.os_version(@user_agents[:itouch]).      should == '4.3.3'
      HeaderParser.os_version(@user_agents[:iphone_ios_4]).should == '4.3.5'
      HeaderParser.os_version(@user_agents[:iphone_ios_5]).should == '5.0'
      HeaderParser.os_version(@user_agents[:ipad_ios_4]).  should == '4.3.5'
      HeaderParser.os_version(@user_agents[:ipad_ios_5]).  should == '5.0'
      HeaderParser.os_version(@user_agents[:nexus_one]).   should == '2.3.4'
      HeaderParser.os_version(@user_agents[:evo]).         should == '2.2'
      HeaderParser.os_version(@user_agents[:galaxy_tab]).  should == '3.1'
    end

    it "parses device_type from known user-agents" do
      HeaderParser.device_type(@user_agents[:itouch]).      should == 'ipod'
      HeaderParser.device_type(@user_agents[:iphone_ios_4]).should == 'iphone'
      HeaderParser.device_type(@user_agents[:iphone_ios_5]).should == 'iphone'
      HeaderParser.device_type(@user_agents[:ipad_ios_4]).  should == 'ipad'
      HeaderParser.device_type(@user_agents[:ipad_ios_5]).  should == 'ipad'
      HeaderParser.device_type(@user_agents[:nexus_one]).   should == 'android'
      HeaderParser.device_type(@user_agents[:evo]).         should == 'android'
      HeaderParser.device_type(@user_agents[:galaxy_tab]).  should == 'android'
    end

    it "parses locales from known accept-languages" do
      HeaderParser.locale('').              should == nil
      HeaderParser.locale('en-us').         should == 'EN'
      HeaderParser.locale('en').            should == 'EN'
      HeaderParser.locale('en-gb;en-us;en').should == 'EN'
    end
  end
end
