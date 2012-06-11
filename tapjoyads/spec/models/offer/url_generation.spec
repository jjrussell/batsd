require 'spec_helper'

describe Offer::UrlGeneration do

  before :each do
    fake_the_web
    @app      = Factory :app
    @offer    = @app.primary_offer
    @currency = Factory :currency
  end

  describe '.display_ad_image_url' do
    context 'with currency passed' do
      it 'should add key param to url ' do
        url = @offer.display_ad_image_url(@app.id, 320, 50, @currency)
        params = CGI::parse(URI(url).query)
        params["key"].first.should == @offer.image_hash(@currency)
      end
    end
        context 'with currency not passed' do
      it 'should add key param' do
        url = @offer.display_ad_image_url(@app.id, 320, 50)
        params = CGI::parse(url)
        params["key"].first.should == @offer.image_hash(nil)
      end
    end
  end

  describe '.preview_display_ad_image_url' do
    it 'should add key param to url ' do
      url = @offer.preview_display_ad_image_url(@app.id, 320, 50)
      params = CGI::parse(URI(url).query)
      params["key"].first.should == @offer.image_hash(nil)
    end
  end
end
