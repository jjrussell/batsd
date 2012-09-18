require 'spec_helper'

describe Offer::UrlGeneration do
  before :each do
    @dummy = Object.new
    @dummy.extend(Offer::UrlGeneration)

    @app      = Factory :app
    @offer    = @app.primary_offer
    @currency = Factory :currency

    @app = FactoryGirl.create :app
    @offer = @app.primary_offer
    @device = FactoryGirl.create(:device)
    @params = { :udid => '123456',
                :tapjoy_device_id => @device.key,
                :publisher_app_id => 'app_id',
                :currency => @currency }
    subject { Offer::UrlGeneration }
    ObjectEncryptor.stub(:encrypt).and_return('some_data')
  end

  describe '#destination_url' do
    context 'Coupon' do
      it 'should call the instructions_url and return a valid url' do
        @offer.item_type = 'Coupon'
        @offer.destination_url(@params).should == "#{API_URL}/coupon_instructions/new?data=some_data"
      end
    end
  end

  describe '#instructions_url' do
    context 'Coupon' do
      it 'should return a valid url to coupon_instructions' do
        @offer.item_type = 'Coupon'
        @offer.instructions_url(@params).should == "#{API_URL}/coupon_instructions/new?data=some_data"
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

  describe '#complete_action_url' do
    before :each do
      params = {
        :tapjoy_device_id => 'TAPJOY_DEVICE_ID',
        :source           => 'TAPJOY_GENERIC_SOURCE',
        :uid              => 'TAPJOY_EXTERNAL_UID',
        :click_key        => 'TAPJOY_HASHED_KEY',
        :invite           => 'TAPJOY_GENERIC_INVITE',
        :survey           => 'TAPJOY_SURVEY',
        :device_click_ip  => 'TAPJOY_DEVICE_CLICK_IP',
        :eid              => 'TJM_EID',
        :data             => 'DATA',
        :hashed_mac       => 'TAPJOY_HASHED_MAC'
      }

      @dummy.stub(:url).and_return("https://example.com/complete/TAPJOY_GENERIC?#{params.to_query}")

      @click_key         = 'click.key'
      @device_click_ip   = 'click.ip'
      @udid              = 'my_device_udid'
      @mac               = 'my_device_mac'
      @publisher_app_id  = 'publisher_app_id'
      @publisher_user_id = 'publisher_user_id'
      @currency = FactoryGirl.create(:currency)
      @device = FactoryGirl.create(:device)

      @source = 'source_token'
      @dummy.stub(:source_token).and_return(@source)

      partner_id = 'partner_id'
      @dummy.stub(:partner_id).and_return(partner_id)
      @uid = Device.advertiser_device_id(@device.key, partner_id)

      @itunes_affil = 'itunes_affil'
      @display_multiplier = 'display_multiplier'


      @options = {
        :click_key             => @click_key,
        :device_click_ip       => @device_click_ip,
        :udid                  => @udid,
        :publisher_app_id      => @publisher_app_id,
        :currency              => @currency,
        :itunes_link_affiliate => @itunes_affil,
        :publisher_user_id     => @publisher_user_id,
        :display_multiplier    => @display_multiplier,
        :mac_address           => @mac,
        :tapjoy_device_id      => @device.key }

      # 'global' macros (with some exceptions, as specified in this file)
      @complete_action_url = @dummy.url.gsub('TAPJOY_DEVICE_ID', @device.key)
      @complete_action_url.gsub!('TAPJOY_GENERIC_SOURCE', @source)
      @complete_action_url.gsub!('TAPJOY_EXTERNAL_UID', @uid)
      @complete_action_url.gsub!('TAPJOY_DEVICE_CLICK_IP', @device_click_ip)
    end

    it "should replace 'global' macros" do
      @dummy.stub(:item_type).and_return('')
      @dummy.complete_action_url(@options).should == @complete_action_url
    end

    context 'for ActionOffers' do
      it 'should not replace any macros' do
        @dummy.stub(:item_type).and_return('ActionOffer')
        @complete_action_url.gsub!(@device.key, 'TAPJOY_DEVICE_ID') # reverse this... ActionOffers are special-cased
        @dummy.complete_action_url(@options.merge(:device_type => nil)).should == @complete_action_url
      end
    end

    context 'for App offers' do
      before(:each) do
        @dummy.stub(:item_type) { 'App' }
        @device = mock()
        Device.stub(:find).and_return(@device)

        @complete_action_url.clone.tap do |url_clone|
          Linkshare.should_receive(:add_params).
            with(url_clone, @itunes_affil).once.
            and_return(url_clone)
        end
      end

      it 'should replace App-offer-specific macros' do
        @dummy.complete_action_url(@options).should match(/click_key=#{Click.hashed_key(@click_key)}/)
      end

      it 'replaces TAPJOY_HASHED_MAC with an empty string if mac is not provided' do
        @device.stub(:mac_address)
        @dummy.complete_action_url(@options.except(:mac_address)).should match(/hashed_mac=&/)
      end

      it 'replaces TAPJOY_HASHED_MAC with a SHA1 hash of the device MAC if provided by SDK' do
        @dummy.complete_action_url(@options).should match(/hashed_mac=#{Digest::SHA1.hexdigest(@mac)}/)
      end

      it 'replaces TAPJOY_HASHED_MAC with a SHA1 hash of the device MAC if provided by Device table' do
        @device.stub(:mac_address).and_return('74e1b6af98a0')
        @dummy.complete_action_url(@options.except(:mac_address)).should match(/hashed_mac=#{Digest::SHA1.hexdigest('74e1b6af98a0')}/)

      end
    end

    context 'for EmailOffers' do
      it 'should append parameters' do
        @dummy.stub(:item_type).and_return('EmailOffer')
        @complete_action_url << "&publisher_app_id=#{@publisher_app_id}"
        @dummy.complete_action_url(@options).should == @complete_action_url
      end
    end

    context 'for GenericOffers' do
      it 'should replace GenericOffer-specific macros' do
        @dummy.stub(:item_type).and_return('GenericOffer')
        @dummy.stub(:id).and_return('id')
        @dummy.stub(:has_variable_payment?).and_return(false)
        @complete_action_url.gsub!('TAPJOY_GENERIC_INVITE', 'key')
        @complete_action_url.gsub!('TAPJOY_GENERIC', @click_key)
        @complete_action_url = "#{WEBSITE_URL}#{@complete_action_url}"
        @complete_action_url.gsub!('TJM_EID', ObjectEncryptor.encrypt(@publisher_app_id))
        data = {
          :offer_id           => @dummy.id,
          :currency_id        => @currency.id,
          :display_multiplier => @display_multiplier
        }
        @complete_action_url.gsub!('DATA', ObjectEncryptor.encrypt(data))
        @dummy.complete_action_url(@options).should == @complete_action_url
      end
    end

    context 'for SurveyOffers' do
      it 'should replace SurveyOffer-specific macros, and encrypt the parameters' do
        @dummy.stub(:item_type).and_return('SurveyOffer')
        @complete_action_url.gsub!('TAPJOY_SURVEY', @click_key)
        @dummy.complete_action_url(@options).should == ObjectEncryptor.encrypt_url(@complete_action_url)
      end
    end

    context 'for VideoOffers and TestVideoOffers' do
      it 'should not replace any macros, and should use a specific url' do
        @dummy.stub(:id).and_return('id')
        params = {
          :offer_id           => @dummy.id,
          :app_id             => @publisher_app_id,
          :currency_id        => @currency.id,
          :udid               => @udid,
          :publisher_user_id  => @publisher_user_id
        }
        @complete_action_url = "#{API_URL}/videos/#{@dummy.id}/complete?data=#{ObjectEncryptor.encrypt(params)}"

        @dummy.stub(:item_type).and_return('VideoOffer')
        @dummy.complete_action_url(@options.clone).should == @complete_action_url

        @dummy.stub(:item_type).and_return('TestVideoOffer')
        @dummy.complete_action_url(@options).should == @complete_action_url
      end
    end

    context 'for DeeplinkOffers' do
      it 'should not replace any macros, and should use a specific url' do
        @dummy.stub(:item_type).and_return('DeeplinkOffer')
        params = { :udid => @udid, :id => @currency.id, :click_key => @click_key }
        @complete_action_url = "#{WEBSITE_URL}/earn?data=#{ObjectEncryptor.encrypt(params)}"
        @dummy.complete_action_url(@options).should == @complete_action_url
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
          :os_version            => 5,
          :tapjoy_device_id      => 'tapjoy-device-id'
        }

        data = {
          :id                    => @offer.id,
          :tapjoy_device_id      => options[:tapjoy_device_id],
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

        expected = "#{API_URL_EXT}/offer_triggered_actions/load_app?data=#{ObjectEncryptor.encrypt(data)}"
        @offer.instructions_url(options).should == expected
      end
    end
  end

  describe '#complete_action_url' do
    context 'Coupon' do
      it 'should return a valid url to coupons complete action' do
        @offer.item_type = 'Coupon'
        @offer.complete_action_url(@params).should == "#{API_URL}/coupons/complete?data=some_data"
      end
    end
  end

  describe '#click_url' do
    before :each do
      @click_params = { :publisher_app => @app, :publisher_user_id => '123',
                        :udid => '123456', :currency_id => 'curr',
                        :source => 'phone', :viewed_at => Time.now, :tapjoy_device_id => 'tapjoy-device-id' }

    end
    context 'item_type is Coupon' do
      it 'should return a valid url to coupons complete action' do
        @offer.item_type = 'Coupon'
        @offer.click_url(@click_params).should == "#{API_URL}/click/coupon?data=some_data"
      end
    end
  end
end
