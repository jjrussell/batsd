require 'spec_helper'

describe GamerDevice do
  before :each do
    fake_the_web
  end

  describe '#dashboard_device_info_tool_url' do
    include ActionController::UrlWriter
    before :each do
      device = Factory :device
      @gamer_device = GamerDevice.new(:device => device)
    end

    it 'matches URL for Rails device_info_tools_url helper' do
      rails_url = device_info_tools_url(:udid     => @gamer_device.device_id,
                                        :host     => URI.parse(DASHBOARD_URL).host,
                                        :protocol => URI.parse(DASHBOARD_URL).scheme)
      @gamer_device.dashboard_device_info_tool_url.should == rails_url
    end
  end
end
