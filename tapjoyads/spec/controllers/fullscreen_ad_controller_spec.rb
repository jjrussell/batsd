require 'spec_helper'

describe FullscreenAdController do
  render_views

  describe '#index' do
    before :each do
      RailsCache.stub(:get).and_return(nil)
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.name = "Consistent Name"
      Offer.stub(:find_in_cache).with(@offer.id).and_return(@offer)
      OfferCacher.stub(:get_offers_prerejected).and_return([@offer])
      @device = FactoryGirl.create(:device)
      Device.stub(:find).and_return(@device)

      @currency = FactoryGirl.create(:currency)
      @currency.stub(:active_currency_sale).and_return(nil)
      @params = {
        :udid => 'stuff',
        :publisher_user_id => 'more_stuff',
        :currency_id => @currency.id,
        :offer_id => @offer.id,
        :image_size => '320x480',
        :publisher_app_id => @currency.app.id,
      }
    end

    context 'without preview = true' do
      it 'records a web request' do
        now = Time.zone.now
        Timecop.freeze(now)

        wr = WebRequest.new
        WebRequest.stub(:new).and_return(wr)

        WebRequest.should_receive(:new).with(:time => Time.zone.now).once
        wr.should_receive(:put_values).with(
          'featured_offer_impression',
          @params.with_indifferent_access.merge(:controller => 'fullscreen_ad', :tapjoy_device_id => @device.key, :action => 'index'),
          @controller.send(:ip_address),
          @controller.send(:geoip_data),
          @request.headers['User-Agent']).once
        wr.should_receive(:save).once

        get(:index, @params)

        wr.offer_id.should == @offer.id
        wr.viewed_at.to_i.should == Time.zone.now.to_i

        Timecop.return
      end

      it 'queues up tracking url calls' do
        @offer.should_receive(:queue_impression_tracking_requests).with(
          :ip_address       => @controller.send(:ip_address),
          :tapjoy_device_id => @device.key,
          :publisher_app_id => @currency.app.id).once

        get(:index, @params)
      end
    end

    context 'with preview = true' do
      before :each do
        @params.merge!(:preview => true)
      end

      it 'does not record a web request' do
        WebRequest.should_not_receive(:new)

        get(:index, @params)
      end

      it 'does not queue up tracking url calls' do
        @offer.should_not_receive(:queue_impression_tracking_requests)

        get(:index, @params)
      end
    end

    it 'renders generated ad template' do
      get(:index, @params)

      response.should be_success
      response.should render_template("fullscreen_ad/index")
    end

    context 'with custom ads' do
      before :each do
        @offer.banner_creatives = %w(320x480 480x320)
        @offer.featured = true
      end

      it 'renders custom creative template' do
        get(:index, @params)

        response.should be_success
        response.body.should have_selector('div#close', :content => 'x')
      end

      it 'includes call-to-action button for rewarded' do
        get(:index, @params)

        reward_amount = @currency.get_visual_reward_amount(@offer)
        expected_text = "Earn #{reward_amount} #{@currency.name}"
        response.should be_success
        response.body.should have_content(expected_text)
      end

      it 'includes call-to-action button for non-rewarded offers' do
        @offer.rewarded = false

        get(:index, @params)

        response.should be_success
        response.body.should have_content('Download')
      end
    end
  end
end
