require 'spec_helper'

describe Offer::UrlGeneration do

  before :each do
    @app      = Factory :app
    @offer    = @app.primary_offer
    @currency = Factory :currency
  end

  describe '#display_ad_image_url' do
    context 'with currency passed' do
      it 'should add key param to url ' do
        url = @offer.display_ad_image_url({ :publisher_app_id => @app.id,
                                            :width => 320,
                                            :height => 50,
                                            :currency => @currency })
        params = CGI::parse(URI(url).query)
        params["key"].first.should == @offer.image_hash(@currency)
      end
    end

    context 'with currency not passed' do
      it 'should add key param' do
        url = @offer.display_ad_image_url({ :publisher_app_id => @app.id,
                                            :width => 320,
                                            :height => 50 })
        params = CGI::parse(url)
        params["key"].first.should == @offer.image_hash(nil)
      end
    end
  end

  describe '#preview_display_ad_image_url' do
    it 'should add key param to url ' do
      url = @offer.display_ad_image_url({ :publisher_app_id => @app.id,
                                          :width => 320,
                                          :height => 50 })
      params = CGI::parse(URI(url).query)
      params["key"].first.should == @offer.image_hash(nil)
    end
  end

  describe '#complete_action_url' do
    context "with a generic offer item" do
      before :each do
        @generic = FactoryGirl.create(:generic_offer)
        @offer = @generic.primary_offer
      end

      it "should substitute tokens in the URL" do
        @offer.url = 'https://example.com/complete/TAPJOY_GENERIC?source=TAPJOY_GENERIC_SOURCE'
        source = @offer.source_token('12345')
        options = {:click_key => 'abcdefg', :udid => 'x', :publisher_app_id => '12345', :currency => 'zxy'}
        @offer.complete_action_url(options).should == "https://example.com/complete/abcdefg?source=#{source}"
      end
    end
  end
end
