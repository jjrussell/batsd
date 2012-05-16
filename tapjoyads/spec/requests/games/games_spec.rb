require 'spec_helper'

describe "Games requests", :type => :request do
  before :each do
    fake_the_web
  end

  let(:testapp) { Factory(:app) }

  describe "GET /games" do
    it "returns 0 when there are no campaigns" do
      visit "/games"
      page.should have_content("Tapjoy Marketplace")
    end
  end
end
