require 'spec_helper'

describe GamerDevice do
  before :each do
    fake_the_web
  end

  describe '#dashboard_device_info_tool_url' do
    before :each do
      device = Factory :device
      @gamer_device = GamerDevice.new(:device => device)
    end

    it 'matches URL for Rails device_info_tools_url helper' do
      @gamer_device.dashboard_device_info_tool_url.should == "#{URI.parse(DASHBOARD_URL).scheme}://#{URI.parse(DASHBOARD_URL).host}/tools/device_info?udid=#{@gamer_device.device_id}"
    end
  end
end
