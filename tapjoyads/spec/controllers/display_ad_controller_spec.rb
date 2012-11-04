require 'spec_helper'

describe DisplayAdController do
  render_views

  describe 'hitting display ad controller' do
    before :each do
      RailsCache.stub(:get).and_return(nil)
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.partner.balance = 10
      Offer.stub(:find_in_cache).with(@offer.id).and_return(@offer)
      OfferCacher.stub(:get_offers_prerejected).and_return([ @offer ])

      @bucket = FakeBucket.new
      S3.stub(:bucket).with(BucketNames::TAPJOY).and_return(@bucket)

      @currency = FactoryGirl.create(:currency)
      Currency.stub(:find_in_cache).with(@currency.id).and_return(@currency)
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
          @custom_banner = read_asset('custom_320x50.png', 'banner_ads')

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

          offer_icon_id = IconHandler.hashed_icon_id(@offer.icon_id)

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

          @generated_banner = read_asset('generated_320x50.png', 'banner_ads')
        end

        it 'returns proper image' do
          get(:image, @params)
          response.content_type.should == 'image/png'
        end

        context 'with old cache key passed and in cache' do
          before :each do
            @image_data = 'pretend image source'
            Mc.should_receive(:distributed_get).and_return(Base64.encode64(@image_data))
          end
          it 'should return decoded image data' do
            get(:image, @params)
            response.content_type.should == 'image/png'
            response.body.should == @image_data
          end
        end

        context 'with old cache key passed and not in cache' do
          before :each do
            @image_data = 'pretend image source'
          end
          it 'should return built image' do
            Magick::Image.any_instance.should_receive(:to_blob).and_return('A Fresh Image')
            get(:image, @params)
            response.body.should == 'A Fresh Image'
          end
        end

        context 'with new cache key passed and is in old cache' do
          it 'should return cached image' do
            display_multiplier = (display_multiplier || 1).to_f
            old_key = "display_ad.#{@params[:currency_id]}.#{@params[:advertiser_app_id]}.#{@params[:size].downcase}.#{display_multiplier}"
            new_key = "display_ad.#{@params[:currency_id]}.#{@params[:advertiser_app_id]}.#{@params[:size].downcase}.#{display_multiplier}.foo"
            Mc.should_receive(:distributed_get_and_put).with([new_key, old_key], false, 1.day).and_return(Base64.encode64('cached image'))
            @params[:key] = 'foo'
            get(:image, @params)
            response.body.should == 'cached image'
          end
        end

        context 'with new cache key passed and is new cache' do
          it 'should  cached image' do
            display_multiplier = (display_multiplier || 1).to_f
            old_key = "display_ad.#{@params[:currency_id]}.#{@params[:advertiser_app_id]}.#{@params[:size].downcase}.#{display_multiplier}"
            new_key = "display_ad.#{@params[:currency_id]}.#{@params[:advertiser_app_id]}.#{@params[:size].downcase}.#{display_multiplier}.foo"
            Mc.distributed_caches.first.should_receive(:get).once.with(new_key).and_return(Base64.encode64('cached image'))
            @params[:key] = 'foo'
            get(:image, @params)
            response.body.should == 'cached image'
          end
        end

        context 'with new cache key passed and is not in cache' do
          it 'should return built  image' do
            display_multiplier = (display_multiplier || 1).to_f
            @params[:key] = 'foo'
            Magick::Image.any_instance.should_receive(:to_blob).and_return('A Fresh Image')
            get(:image, @params)
            response.body.should == 'A Fresh Image'
          end
        end
      end
    end

    describe '#index' do
      before :each do
        td_icon     = read_asset('tap_defense.jpg', 'icons')
        round_mask  = read_asset('round_mask.png',  'display')
        icon_shadow = read_asset('icon_shadow.png', 'display')

        offer_icon_id = IconHandler.hashed_icon_id(@offer.icon_id)

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
        @bucket.stub(:objects).and_return({ "display/self_ad_bg_640x100.png" => 'file' })
        obj_ad_bg = @bucket.objects["display/self_ad_bg_640x100.png"]
        obj_ad_bg.stub(:read).and_return(ad_bg)
      end

      context 'valid OfferList' do
        before :each do
          offer_list = double(OfferList)
          OfferList.stub(:new).and_return(offer_list)
          offer_list.stub(:weighted_rand).and_return(@offer)
        end
        it 'should mark the pub app as using non-html responses' do
          message = { :class_name => 'App', :id => @currency.app.id, :attributes => { :uses_non_html_responses => true } }
          Sqs.should_receive(:send_message).with(QueueNames::RECORD_UPDATES, Base64::encode64(Marshal.dump(message))).once

          get(:index, @params)
        end

        it 'should queue up tracking url calls' do
          @offer.should_receive(:queue_impression_tracking_requests).with(
            :ip_address       => @controller.send(:ip_address),
            :udid             => 'stuff',
            :publisher_app_id => @currency.app.id).once

          get(:index, @params)
        end
      end

      context 'with unfilled request' do
        before :each do
          OfferCacher.stub(:get_offers_prerejected).and_return([])
        end

        it 'should not queue up tracking url calls' do
          Offer.any_instance.should_not_receive(:queue_impression_tracking_requests)

          get(:index, @params)
        end
      end

      context 'with custom ad' do
        before :each do
          offer_list = double(OfferList)
          OfferList.stub(:new).and_return(offer_list)
          offer_list.stub(:weighted_rand).and_return(@offer)
          @offer.banner_creatives = %w(320x50 640x100)
          @offer.approved_banner_creatives = %w(320x50 640x100)
          @offer.rewarded = false
        end

        it 'returns proper image data in json' do
          bucket_objects = { @offer.banner_creative_path('320x50') => 'file' }
          @bucket.stub(:objects).and_return(bucket_objects)
          s3_object = @bucket.objects[@offer.banner_creative_path('320x50')]
          custom_banner = read_asset('custom_320x50.png', 'banner_ads')
          s3_object.stub(:read).and_return(custom_banner)

          get(:index, @params.merge(:format => 'json'))

          response.content_type.should == 'application/json'
          Base64.decode64(assigns['image']).should == custom_banner
          expect { JSON.parse(response.body) }.not_to raise_error
        end

        it 'returns proper image data in xml' do
          bucket_objects = { @offer.banner_creative_path('640x100') => 'file' }
          @bucket.stub(:objects).and_return(bucket_objects)
          s3_object = @bucket.objects[@offer.banner_creative_path('640x100')]
          custom_banner = read_asset('custom_640x100.png', 'banner_ads')
          s3_object.stub(:read).and_return(custom_banner)

          get(:index, @params.merge(:format => "xml"))
          response.content_type.should == 'application/xml'
          Base64.decode64(assigns['image']).should == custom_banner
        end
      end

      context 'with generated ad' do
        it 'returns proper image data in json' do
          ad_bg = read_asset('self_ad_bg_320x50.png', 'display')
          bucket_objects = { "display/self_ad_bg_320x50.png" => 'some_file' }
          @bucket.stub(:objects).and_return(bucket_objects)
          obj_ad_bg = @bucket.objects["display/self_ad_bg_320x50.png"]
          obj_ad_bg.stub(:read).and_return(ad_bg)

          get(:index, @params.merge(:format => 'json'))
          response.content_type.should == 'application/json'
        end

        it 'returns proper image data in xml' do
          get(:index, @params.merge(:format => "xml"))
          response.content_type.should == 'application/xml'
        end
      end
    end

    describe '#webview' do

      context 'valid OfferList' do
        before :each do
          offer_list = double(OfferList)
          OfferList.stub(:new).and_return(offer_list)
          offer_list.stub(:weighted_rand).and_return(@offer)
        end
        it 'should queue up tracking url calls' do
          @offer.should_receive(:queue_impression_tracking_requests).with(
            :ip_address       => @controller.send(:ip_address),
            :udid             => 'stuff',
            :publisher_app_id => @currency.app.id).once

          get(:webview, @params)
        end
      end

      context 'with custom ad' do
        before :each do
          offer_list = double(OfferList)
          OfferList.stub(:new).and_return(offer_list)
          offer_list.stub(:weighted_rand).and_return(@offer)
          @offer.banner_creatives = %w(320x50)
          @offer.approved_banner_creatives = %w(320x50)
          @offer.rewarded = false
        end

        it 'contains proper image link' do
          get(:webview, @params)

          assigns['image_url'].should be_starts_with(CLOUDFRONT_URL)
          assigns['image_url'].should == @offer.display_ad_image_url(:publisher_app_id => @currency.app.id,
                                                                     :width => 320,
                                                                     :height => 50,
                                                                     :currency_id => @currency.id)
        end
      end

      context 'with generated ad' do
        before :each do
          offer_list = double(OfferList)
          OfferList.stub(:new).and_return(offer_list)
          offer_list.stub(:weighted_rand).and_return(@offer)
        end
        it 'contains proper image link' do
          get(:webview, @params)

          assigns['image_url'].should be_starts_with(API_URL)
          assigns['image_url'].should == @offer.display_ad_image_url(:publisher_app_id => @currency.app.id,
                                                                     :width => 320,
                                                                     :height => 50,
                                                                     :currency => @currency)
        end
      end
    end
  end
end
