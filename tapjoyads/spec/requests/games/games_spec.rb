require 'spec_helper'

describe "Games requests", :type => :request do
  let(:testapp) { FactoryGirl.create(:app) }

  describe "GET /games" do
    it "returns 0 when there are no campaigns" do
      visit "/games"
      page.should have_content("Tapjoy Marketplace")
    end
  end
end
