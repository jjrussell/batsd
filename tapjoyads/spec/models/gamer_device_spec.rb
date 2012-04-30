require 'spec_helper'

describe Gamer do
  before :each do
    fake_the_web
  end

  describe '#info_tool_url' do
    include ActionController::UrlWriter
    before :each do
      device = Factory :device
      @gamer_device = GamerDevice.new(:device => device)
    end

    it 'matches URL for Rails device_info_tools_url helper' do
      rails_url = device_info_tools_url(:udid => @gamer_device.device_id,
                                        :host => URI.parse(DASHBOARD_URL).host)
      @gamer_device.info_tool_url.should == rails_url
    end
  end
end
