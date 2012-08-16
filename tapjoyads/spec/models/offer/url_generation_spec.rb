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
        params["key"].first.should == @offer.display_ad_image_hash(@currency)
      end
    end

    context 'with currency not passed' do
      it 'should add key param' do
        url = @offer.display_ad_image_url({ :publisher_app_id => @app.id,
                                            :width => 320,
                                            :height => 50 })
        params = CGI::parse(url)
        params["key"].first.should == @offer.display_ad_image_hash(nil)
      end
    end
  end

  describe '#preview_display_ad_image_url' do
    it 'should add key param to url ' do
      url = @offer.display_ad_image_url({ :publisher_app_id => @app.id,
                                          :width => 320,
                                          :height => 50 })
      params = CGI::parse(URI(url).query)
      params["key"].first.should == @offer.display_ad_image_hash(nil)
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

  describe '#instructions_url' do
    context "with protocol handler" do
      before :each do
        @generic = FactoryGirl.create(:generic_offer, :trigger_action => 'Protocol Handler')
        @offer = @generic.primary_offer
      end

      it "should go to correct offer trigger url" do
        options = {
          :udid                  => '123',
          :publisher_app_id      => '456',
          :currency              => @currency,
          :click_key             => 'abcedefg',
          :language_code         => 'en',
          :itunes_link_affiliate => 'hijklmno',
          :display_multiplier    => 1,
          :library_version       => 1,
          :os_version            => 5
        }
 
        data = {
          :id                    => @offer.id,
          :udid                  => options[:udid],
          :publisher_app_id      => options[:publisher_app_id],
          :click_key             => options[:click_key],
          :itunes_link_affiliate => options[:itunes_link_affiliate],
          :currency_id           => @currency.id,
          :language_code         => options[:language_code],
          :display_multiplier    => options[:display_multiplier],
          :library_version       => options[:library_version],
          :os_version            => options[:os_version]
        }

        expected = "#{API_URL}/offer_triggered_actions/load_app?data=#{ObjectEncryptor.encrypt(data)}"
        @offer.instructions_url(options).should == expected
      end
    end
  end

end
