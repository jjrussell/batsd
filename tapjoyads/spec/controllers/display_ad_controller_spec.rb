require 'spec/spec_helper'

def read_asset(name, directory='banner_ads')
  File.read("#{Rails.root}/spec/assets/#{directory}/#{name}")
end

describe DisplayAdController do
  render_views
  before :each do
    fake_the_web
  end

  describe 'hitting display ad controller' do
    before :each do
      RailsCache.stub(:get).and_return(nil)
      @offer = Factory(:app).primary_offer
      Offer.stub(:find_in_cache).with(@offer.id).and_return(@offer)
      OfferCacher.stub(:get_unsorted_offers_prerejected).and_return([ @offer ])

      @bucket = S3.bucket(BucketNames::TAPJOY)
      S3.stub(:bucket).with(BucketNames::TAPJOY).and_return(@bucket)

      @currency = Factory(:currency)
      @params = {
        :udid => 'stuff',
        :publisher_user_id => 'more_stuff',
        :currency_id => @currency.id,
        :app_id => @currency.app.id,
      }
    end

    describe '#image' do
      before :each do
        @params.merge!(
          :advertiser_app_id => @offer.id,
          :size => '320X50',
          :publisher_app_id => @params[:app_id])
        @params.delete(:app_id)
      end

      context 'with custom ad' do
        before :each do
          @offer.banner_creatives = %w(320x50)
          @offer.approved_banner_creatives = %w(320x50)
          @offer.rewarded = false

          object = @bucket.objects[@offer.banner_creative_path('320x50')]
          @custom_banner = read_asset('custom_320x50.png')

          object.stub(:read).and_return(@custom_banner)
          bucket_objects = { @offer.banner_creative_path('320x50') => object }
          @bucket.stub(:objects).and_return(bucket_objects)
        end

        it 'returns proper image' do
          get(:image, @params)

          response.content_type.should == 'image/png'
          response.body.should == @custom_banner
        end
      end

      context 'with generated ad' do
        before :each do
          ad_bg       = read_asset('self_ad_bg_320x50.png', 'display')
          td_icon     = read_asset('tap_defense.jpg',       'icons')
          round_mask  = read_asset('round_mask.png',        'display')
          icon_shadow = read_asset('icon_shadow.png',       'display')

          offer_icon_id = Offer.hashed_icon_id(@offer.icon_id)

          obj_ad_bg       = @bucket.objects["display/self_ad_bg_320x50.png"]
          obj_td_icon     = @bucket.objects["icons/src/#{offer_icon_id}.jpg"]
          obj_round_mask  = @bucket.objects["display/round_mask.png"]
          obj_icon_shadow = @bucket.objects["display/icon_shadow.png"]
          objects = {
            "display/self_ad_bg_320x50.png" => obj_ad_bg,
            "icons/src/#{offer_icon_id}.jpg" => obj_td_icon,
            "display/round_mask.png" => obj_round_mask,
            "display/icon_shadow.png" => obj_icon_shadow,
          }

          @bucket.stub(:objects).and_return(objects)
          obj_ad_bg.stub(:read).and_return(ad_bg)
          obj_td_icon.stub(:read).and_return(td_icon)
          obj_round_mask.stub(:read).and_return(round_mask)
          obj_icon_shadow.stub(:read).and_return(icon_shadow)

          @generated_banner = read_asset('generated_320x50.png')
        end

        it 'returns proper image' do
          get(:image, @params)
          response.content_type.should == 'image/png'
        end
      end
    end

    describe '#index' do

      before :each do
        td_icon     = read_asset('tap_defense.jpg', 'icons')
        round_mask  = read_asset('round_mask.png',  'display')
        icon_shadow = read_asset('icon_shadow.png', 'display')

        offer_icon_id = Offer.hashed_icon_id(@offer.icon_id)

        obj_td_icon = @bucket.objects["icons/src/#{offer_icon_id}.jpg"]
        obj_round_mask = @bucket.objects["display/round_mask.png"]
        obj_icon_shadow = @bucket.objects["display/icon_shadow.png"]
        objects = {
          "icons/src/#{offer_icon_id}.jpg" => obj_td_icon,
          "display/round_mask.png" => obj_round_mask,
          "display/icon_shadow.png" => obj_icon_shadow,
        }
        @bucket.stub(:objects).and_return(objects)
        obj_td_icon.stub(:read).and_return(td_icon)
        obj_round_mask.stub(:read).and_return(round_mask)
        obj_icon_shadow.stub(:read).and_return(icon_shadow)

        ad_bg = read_asset('self_ad_bg_640x100.png', 'display')
        obj_ad_bg = @bucket.objects["display/self_ad_bg_640x100.png"]
        @bucket.stub(:objects).and_return({ "display/self_ad_bg_640x100.png" => obj_ad_bg })
        obj_ad_bg.stub(:read).and_return(ad_bg)
      end

      it 'should queue up tracking url calls' do
        @offer.should_receive(:queue_impression_tracking_requests).once

        get(:index, @params)
      end

      context 'with unfilled request' do
        before :each do
          OfferCacher.stub(:get_unsorted_offers_prerejected).and_return([])
        end

        it 'should not queue up tracking url calls' do
          Offer.any_instance.should_receive(:queue_impression_tracking_requests).never

          get(:index, @params)
        end
      end

      context 'with custom ad' do
        before :each do
          @offer.banner_creatives = %w(320x50 640x100)
          @offer.approved_banner_creatives = %w(320x50 640x100)
          @offer.rewarded = false
        end

        it 'returns proper image data in json' do
          object = @bucket.objects[@offer.banner_creative_path('320x50')]
          custom_banner = read_asset('custom_320x50.png')
          object.stub(:read).and_return(custom_banner)
          bucket_objects = { @offer.banner_creative_path('320x50') => object }
          @bucket.stub(:objects).and_return(bucket_objects)

          get(:index, @params.merge(:format => 'json'))

          response.content_type.should == 'application/json'
          Base64.decode64(assigns['image']).should == custom_banner
          expect { JSON.parse(response.body) }.should_not raise_error
        end

        it 'returns proper image data in xml' do
          object = @bucket.objects[@offer.banner_creative_path('640x100')]
          custom_banner = read_asset('custom_640x100.png')
          object.stub(:read).and_return(custom_banner)
          bucket_objects = { @offer.banner_creative_path('640x100') => object }
          @bucket.stub(:objects).and_return(bucket_objects)

          get(:index, @params)
          response.content_type.should == 'application/xml'
          Base64.decode64(assigns['image']).should == custom_banner
        end
      end

      context 'with generated ad' do
        it 'returns proper image data in json' do
          ad_bg = read_asset('self_ad_bg_320x50.png', 'display')
          obj_ad_bg = @bucket.objects["display/self_ad_bg_320x50.png"]
          bucket_objects = { "display/self_ad_bg_320x50.png" => obj_ad_bg }
          @bucket.stub(:objects).and_return(bucket_objects)
          obj_ad_bg.stub(:read).and_return(ad_bg)

          get(:index, @params.merge(:format => 'json'))
          response.content_type.should == 'application/json'
        end

        it 'returns proper image data in xml' do
          get(:index, @params)
          response.content_type.should == 'application/xml'
        end
      end
    end

    describe '#webview' do

      it 'should queue up tracking url calls' do
        @offer.should_receive(:queue_impression_tracking_requests).once

        get(:webview, @params)
      end

      context 'with custom ad' do
        before :each do
          @offer.banner_creatives = %w(320x50)
          @offer.approved_banner_creatives = %w(320x50)
          @offer.rewarded = false
        end

        it 'contains proper image link' do
          get(:webview, @params)

          assigns['image_url'].should be_starts_with(CLOUDFRONT_URL)
          assigns['image_url'].should == @offer.display_ad_image_url(@currency.app.id, 320, 50, @currency.id)
        end
      end

      context 'with generated ad' do
        it 'contains proper image link' do
          get(:webview, @params)

          assigns['image_url'].should be_starts_with(API_URL)
          assigns['image_url'].should == @offer.display_ad_image_url(@currency.app.id, 320, 50, @currency.id)
        end
      end
    end
  end
end
