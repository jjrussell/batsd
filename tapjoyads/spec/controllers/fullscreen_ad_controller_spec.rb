require 'spec/spec_helper'

describe FullscreenAdController do
  render_views

  describe '#index' do
    before :each do
      RailsCache.stubs(:get).returns(nil)
      @offer = Factory(:app).primary_offer
      @offer.name = "Consistent Name"
      Offer.stubs(:find_in_cache).with(@offer.id).returns(@offer)
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])

      @currency = Factory(:currency)
      @params = {
        :udid => 'stuff',
        :publisher_user_id => 'more_stuff',
        :currency_id => @currency.id,
        :offer_id => @offer.id,
        :image_size => '320x480',
        :publisher_app_id => @currency.app.id,
      }
    end

    it 'renders generated ad template' do
      get(:index, @params)

      response.should be_success
      response.should render_template("fullscreen_ad/index")
    end

    context 'with third party tracking URLs' do
      it 'should generate hidden image tags' do
        url = "https://dummyurl.com"
        @offer.impression_tracking_urls = [url]

        get(:index, @params)
        response.body.should include(image_tag(url, :style => 'display:none;'))
      end
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

      context 'with third party tracking URLs' do
        it 'should generate hidden image tags' do
          url = "https://dummyurl.com"
          @offer.impression_tracking_urls = [url]

          get(:index, @params)
          response.body.should include(image_tag(url, :style => 'display:none;'))
        end
      end
    end
  end
end
