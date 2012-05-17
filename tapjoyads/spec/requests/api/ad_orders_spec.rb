require 'spec_helper'

describe "Ad orders" do
  before :each do
    fake_the_web
  end

  let(:testapp) { Factory(:app) }

  describe "GET /get_ad_order" do
    it "returns 0 when there are no campaigns" do
      udid = 'testudid'

      get "/service1.asmx/GetAdOrder", { :udid => udid, :app_id => testapp.id}
      response.status.should be(200)

      xml = Hpricot(response.body)
      xml.search("adorderdata").count.should == 1
    end
  end
end
