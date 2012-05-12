require 'spec_helper'

describe Click do
  before :each do
    SimpledbResource.reset_connection
  end

  describe "#url_to_resolve" do
    before :each do
      @click = Factory(:click)
    end

    context "when generic click" do
      before :each do
        @click.type = 'generic'
      end

      it "creates a url that goes to offer_completed controller" do
        expected = "#{API_URL}/offer_completed?click_key=#{@click.key}"
        @click.send(:url_to_resolve).should == expected
      end
    end
    context "when not generic click" do
      before :each do
        @click.type = 'featured_install'
      end

      it "creates a connect call url" do
        expected = "#{API_URL}/connect?app_id=#{@click.advertiser_app_id}&udid=#{@click.udid}&consistent=true"
        @click.send(:url_to_resolve).should == expected
      end
    end
  end

  describe '#dashboard_device_info_tool_url' do
    include ActionController::UrlWriter
    before :each do
      @click = Factory(:click)
    end

    it 'matches URL for Rails device_info_tools_url helper' do
      rails_url = device_info_tools_url(:click_key => @click.key,
                                        :host      => URI.parse(DASHBOARD_URL).host,
                                        :protocol  => URI.parse(DASHBOARD_URL).scheme)
      @click.dashboard_device_info_tool_url.should == rails_url
    end
  end
end
