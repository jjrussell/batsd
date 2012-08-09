require 'spec_helper'

class DummyClass
end

describe Offer::UrlGeneration do

  before :each do
    @dummy_class = DummyClass.new
    @dummy_class.extend(Offer::UrlGeneration)

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
      it 'should not replace any macros' do
        @dummy_class.stub(:item_type).and_return('ActionOffer')
        @complete_action_url.gsub!(@udid, 'TAPJOY_UDID') # reverse this... ActionOffers are special-cased
        @dummy_class.complete_action_url(@options).should == @complete_action_url
      end
    end

    context 'for App offers' do
      it 'should replace App-offer-specific macros' do
        @dummy_class.stub(:item_type).and_return('App')
        Linkshare.should_receive(:add_params).with(@complete_action_url.clone, @itunes_affil).once.and_return(@complete_action_url.clone)
        @complete_action_url.gsub!('TAPJOY_HASHED_KEY', Click.hashed_key(@click_key))
        @dummy_class.complete_action_url(@options).should == @complete_action_url
      end
    end

    context 'for EmailOffers' do
      it 'should append parameters' do
        @dummy_class.stub(:item_type).and_return('EmailOffer')
        @complete_action_url << "&publisher_app_id=#{@publisher_app_id}"
        @dummy_class.complete_action_url(@options).should == @complete_action_url
      end
    end

    context 'for GenericOffers' do
      it 'should replace GenericOffer-specific macros' do
        @dummy_class.stub(:item_type).and_return('GenericOffer')
        @dummy_class.stub(:has_variable_payment?).and_return(false)
        @complete_action_url.gsub!('TAPJOY_GENERIC_INVITE', 'key')
        @complete_action_url.gsub!('TAPJOY_GENERIC', @click_key)
        @dummy_class.complete_action_url(@options).should == @complete_action_url
      end
    end

    context 'for SurveyOffers' do
      it 'should replace SurveyOffer-specific macros, and encrypt the parameters' do
        @dummy_class.stub(:item_type).and_return('SurveyOffer')
        @complete_action_url.gsub!('TAPJOY_SURVEY', @click_key)
        @dummy_class.complete_action_url(@options).should == ObjectEncryptor.encrypt_url(@complete_action_url)
      end
    end

    context 'for VideoOffers and TestVideoOffers' do
      it 'should not replace any macros, and should use a specific url' do
        @dummy_class.stub(:id).and_return('id')
        params = {
          :offer_id           => @dummy_class.id,
          :app_id             => @publisher_app_id,
          :currency_id        => @currency.id,
          :udid               => @udid,
          :publisher_user_id  => @publisher_user_id
        }
        @complete_action_url = "#{API_URL}/videos/#{@dummy_class.id}/complete?data=#{ObjectEncryptor.encrypt(params)}"

        @dummy_class.stub(:item_type).and_return('VideoOffer')
        @dummy_class.complete_action_url(@options.clone).should == @complete_action_url

        @dummy_class.stub(:item_type).and_return('TestVideoOffer')
        @dummy_class.complete_action_url(@options).should == @complete_action_url
      end
    end

    context 'for DeeplinkOffers' do
      it 'should not replace any macros, and should use a specific url' do
        @dummy_class.stub(:item_type).and_return('DeeplinkOffer')
        params = { :udid => @udid, :id => @currency.id, :click_key => @click_key }
        @complete_action_url = "#{WEBSITE_URL}/earn?data=#{ObjectEncryptor.encrypt(params)}"
        @dummy_class.complete_action_url(@options).should == @complete_action_url
      end
    end

  end

end
