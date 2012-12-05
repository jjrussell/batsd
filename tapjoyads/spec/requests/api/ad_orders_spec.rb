require 'spec_helper'

describe "Ad orders" do
  let(:testapp) { FactoryGirl.create(:app) }

  describe "GET /get_ad_order" do
    before :each do
      device = FactoryGirl.create(:device)
      DeviceIdentifier.stub(:find_device_from_params).and_return(device)
    end
    it "returns 0 when there are no campaigns" do
      udid = 'testudid'

      get "/get_ad_order", { :udid => udid, :app_id => testapp.id}
      response.status.should be(200)

      xml = Hpricot(response.body)
      xml.search("adorderdata").count.should == 1
    end
  end
end
