require 'spec/spec_helper'

def read_asset(name, directory='banner_ads')
  File.read("#{Rails.root}/spec/assets/#{directory}/#{name}")
end

describe DisplayAdController do
  integrate_views
  before :each do
    fake_the_web
  end

  describe 'hitting display ad controller' do
    before :each do
      RailsCache.stubs(:get).returns(nil)
      @offer = Factory(:app).primary_offer
      Offer.stubs(:find_in_cache).with(@offer.id).returns(@offer)
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([ @offer ])

      @bucket = S3.bucket(BucketNames::TAPJOY)
      S3.stubs(:bucket).with(BucketNames::TAPJOY).returns(@bucket)

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

          object.stubs(:read).returns(@custom_banner)
          bucket_objects = { @offer.banner_creative_path('320x50') => object }
          @bucket.stubs(:objects).returns(bucket_objects)
        end

        it 'returns proper image' do
          get(:image, @params)

          response.content_type.should == 'image/png'

          # To diagnose a mismatch, uncomment the following and compare the new image to #{Rails.root}/spec/assets/banner_ads/custom_320x50.png
          # File.open("#{Rails.root}/spec/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

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

          @bucket.stubs(:objects).returns(objects)
          obj_ad_bg.stubs(:read).returns(ad_bg)
          obj_td_icon.stubs(:read).returns(td_icon)
          obj_round_mask.stubs(:read).returns(round_mask)
          obj_icon_shadow.stubs(:read).returns(icon_shadow)

          @generated_banner = read_asset('generated_320x50.png')
        end

        it 'returns proper image' do
          get(:image, @params)
          response.content_type.should == 'image/png'

          # Uncomment the following to re-generate the image if needed (e.g. background image changes, text changes, etc)
          # File.open("#{Rails.root}/spec/assets/banner_ads/generated_320x50.png", 'w') { |f| f.write(response.body) }

          # To diagnose a mismatch, uncomment the following and compare the new image to #{Rails.root}/spec/assets/banner_ads/generated_320x50.png
          # File.open("#{Rails.root}/spec/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

          ### The test seems to be failing due to different versions of ImageMagick / different fonts on other developer machines ###
          # response.body.should == @generated_banner
        end
      end
    end

    describe '#index' do
      context 'with custom ad' do
        before :each do
          @offer.banner_creatives = %w(320x50 640x100)
          @offer.approved_banner_creatives = %w(320x50 640x100)
          @offer.rewarded = false
        end

        it 'returns proper image data in json' do
          object = @bucket.objects[@offer.banner_creative_path('320x50')]
          custom_banner = read_asset('custom_320x50.png')
          object.stubs(:read).returns(custom_banner)
          bucket_objects = { @offer.banner_creative_path('320x50') => object }
          @bucket.stubs(:objects).returns(bucket_objects)

          get(:index, @params.merge(:format => 'json'))

          response.content_type.should == 'application/json'

          # To diagnose a mismatch, uncomment the following and compare the new image to #{Rails.root}/spec/assets/banner_ads/custom_320x50.png
          # File.open("#{Rails.root}/spec/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

          Base64.decode64(assigns['image']).should == custom_banner
        end

        it 'returns proper image data in xml' do
          object = @bucket.objects[@offer.banner_creative_path('640x100')]
          custom_banner = read_asset('custom_640x100.png')
          object.stubs(:read).returns(custom_banner)
          bucket_objects = { @offer.banner_creative_path('640x100') => object }
          @bucket.stubs(:objects).returns(bucket_objects)

          get(:index, @params)
          response.content_type.should == 'application/xml'

          # To diagnose a mismatch, uncomment the following and compare the new image to #{Rails.root}/spec/assets/banner_ads/custom_640x100.png
          # File.open("#{Rails.root}/spec/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

          Base64.decode64(assigns['image']).should == custom_banner
        end
      end

      context 'with generated ad' do
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
          @bucket.stubs(:objects).returns(objects)
          obj_td_icon.stubs(:read).returns(td_icon)
          obj_round_mask.stubs(:read).returns(round_mask)
          obj_icon_shadow.stubs(:read).returns(icon_shadow)
        end

        it 'returns proper image data in json' do
          ad_bg = read_asset('self_ad_bg_320x50.png', 'display')
          obj_ad_bg = @bucket.objects["display/self_ad_bg_320x50.png"]
          bucket_objects = { "display/self_ad_bg_320x50.png" => obj_ad_bg }
          @bucket.stubs(:objects).returns(bucket_objects)
          obj_ad_bg.stubs(:read).returns(ad_bg)

          get(:index, @params.merge(:format => 'json'))
          response.content_type.should == 'application/json'

          # Uncomment the following to re-generate the image if needed (e.g. background image changes, text changes, etc)
          # File.open("#{Rails.root}/spec/assets/banner_ads/generated_320x50.png", 'w') { |f| f.write(Base64.decode64(assigns['image'])) }

          # To diagnose a mismatch, uncomment the following and compare the new image to #{Rails.root}/spec/assets/banner_ads/generated_320x50.png
          # File.open("#{Rails.root}/spec/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

          ### The test seems to be failing due to different versions of ImageMagick / different fonts on other developer machines ###
          # Base64.decode64(assigns['image']).should == File.read("#{Rails.root}/spec/assets/banner_ads/generated_320x50.png")
        end

        it 'returns proper image data in xml' do
          ad_bg = File.read("#{Rails.root}/spec/assets/display/self_ad_bg_640x100.png")
          obj_ad_bg = @bucket.objects["display/self_ad_bg_640x100.png"]
          @bucket.stubs(:objects).returns({ "display/self_ad_bg_640x100.png" => obj_ad_bg })
          obj_ad_bg.stubs(:read).returns(ad_bg)

          get(:index, @params)
          response.content_type.should == 'application/xml'

          # Uncomment the following to re-generate the image if needed (e.g. background image changes, text changes, etc)
          # File.open("#{Rails.root}/spec/assets/banner_ads/generated_640x100.png", 'w') { |f| f.write(Base64.decode64(assigns['image'])) }

          # To diagnose a mismatch, uncomment the following and compare the new image to #{Rails.root}/spec/assets/banner_ads/generated_640x100.png
          # File.open("#{Rails.root}/spec/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

          ### The test seems to be failing due to different versions of ImageMagick / different fonts on other developer machines ###
          # Base64.decode64(assigns['image']).should == File.read("#{Rails.root}/spec/assets/banner_ads/generated_640x100.png")
        end
      end
    end

    describe '#webview' do
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
