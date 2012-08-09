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
  end

  describe '#complete_action_url' do

    before :each do
      params = {
        :udid => 'TAPJOY_UDID',
        :source => 'TAPJOY_GENERIC_SOURCE',
        :uid => 'TAPJOY_EXTERNAL_UID',
        :click_key => 'TAPJOY_HASHED_KEY',
        :invite => 'TAPJOY_GENERIC_INVITE',
        :survey => 'TAPJOY_SURVEY'
      }
      @dummy_class.stub(:url).and_return("https://example.com/complete/TAPJOY_GENERIC?#{params.to_query}")

      @click_key = 'click.key'
      @udid = 'my_device_udid'
      @publisher_app_id = 'publisher_app_id'
      @publisher_user_id = 'publisher_user_id'
      @currency = FactoryGirl.create(:currency)

      @source = 'source_token'
      @dummy_class.stub(:source_token).and_return(@source)

      partner_id = 'partner_id'
      @dummy_class.stub(:partner_id).and_return(partner_id)
      @uid = Device.advertiser_device_id(@udid, partner_id)

      @itunes_affil = 'itunes_affil'

      @options = {
        :click_key             => @click_key,
        :udid                  => @udid,
        :publisher_app_id      => @publisher_app_id,
        :currency              => @currency,
        :itunes_link_affiliate => @itunes_affil,
        :publisher_user_id     => @publisher_user_id }

      # 'global' macros (with some exceptions, as specified in this file)
      @complete_action_url = @dummy_class.url.gsub('TAPJOY_UDID', @udid)
      @complete_action_url.gsub!('TAPJOY_GENERIC_SOURCE', @source)
      @complete_action_url.gsub!('TAPJOY_EXTERNAL_UID', @uid)
    end

    it "should replace 'global' macros" do
      @dummy_class.stub(:item_type).and_return('')
      @dummy_class.complete_action_url(@options).should == @complete_action_url
    end

    context 'for ActionOffers' do
      it 'should not replace the TAPJOY_UDID macro' do
        @dummy_class.stub(:item_type).and_return('ActionOffer')
        @complete_action_url.gsub!(@udid, 'TAPJOY_UDID') # reverse this... ActionOffers are special-cased
        @dummy_class.complete_action_url(@options).should == @complete_action_url
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
end
