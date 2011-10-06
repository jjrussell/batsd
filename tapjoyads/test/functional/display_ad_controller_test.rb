require 'test_helper'

class DisplayAdControllerTest < ActionController::TestCase

  context "hitting display ad controller" do
    setup do
      RailsCache.stubs(:get).returns(nil)
      @offer = Factory(:app).primary_offer
      @offer.name = "Consistent Name"
      Offer.stubs(:find_in_cache).with(@offer.id).returns(@offer)
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])

      @right_aws_bucket = S3.bucket(BucketNames::TAPJOY)
      S3.stubs(:bucket).with(BucketNames::TAPJOY).returns(@right_aws_bucket)

      aws_sdk_s3 = AWS::S3.new
      @aws_sdk_bucket = AWS::S3::Bucket.new(BucketNames::TAPJOY)
      buckets = { BucketNames::TAPJOY => @aws_sdk_bucket }
      aws_sdk_s3.stubs(:buckets).returns(buckets)
      AWS::S3.stubs(:new).returns(aws_sdk_s3)

      @currency = Factory(:currency)
      @params = { :udid => 'stuff', :publisher_user_id => 'more_stuff', :currency_id => @currency.id, :app_id => @currency.app.id }
    end

    context "when calling 'image'" do
      setup do
        @params.merge!(:advertiser_app_id => @offer.id, :size => '320X50', :publisher_app_id => @params[:app_id])
        @params.delete(:app_id)
      end

      context "with custom ad" do
        setup do
          @offer.banner_creatives = %w(320x50)
          @offer.rewarded = false

          aws_sdk_object = AWS::S3::S3Object.new(@aws_sdk_bucket, @offer.banner_creative_path('320x50'))
          @custom_banner = File.read("#{RAILS_ROOT}/test/assets/banner_ads/custom_320x50.png")
          aws_sdk_object.stubs(:read).returns(@custom_banner)
          objects = { @offer.banner_creative_path('320x50') => aws_sdk_object }
          @aws_sdk_bucket.stubs(:objects).returns(objects)
        end

        should "return proper image" do
          response = get(:image, @params)
          assert_equal('image/png', response.content_type)

          # To diagnose a mismatch, uncomment the following and compare the new image to #{RAILS_ROOT}/test/assets/banner_ads/custom_320x50.png
          # File.open("#{RAILS_ROOT}/test/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

          assert(@custom_banner == response.body)
        end
      end

      context "with generated ad" do
        setup do
          ad_bg = File.read("#{RAILS_ROOT}/test/assets/display/self_ad_bg_320x50.png")
          td_icon = File.read("#{RAILS_ROOT}/test/assets/icons/tap_defense.jpg")
          round_mask = File.read("#{RAILS_ROOT}/test/assets/display/round_mask.png")
          icon_shadow = File.read("#{RAILS_ROOT}/test/assets/display/icon_shadow.png")

          @right_aws_bucket.stubs(:get).with("display/self_ad_bg_320x50.png").returns(ad_bg)
          @right_aws_bucket.stubs(:get).with("icons/src/#{Offer.hashed_icon_id(@offer.icon_id)}.jpg").returns(td_icon)
          @right_aws_bucket.stubs(:get).with("display/round_mask.png").returns(round_mask)
          @right_aws_bucket.stubs(:get).with("display/icon_shadow.png").returns(icon_shadow)

          @generated_banner = File.read("#{RAILS_ROOT}/test/assets/banner_ads/generated_320x50.png")
        end

        should "return proper image" do
          response = get(:image, @params)
          assert_equal('image/png', response.content_type)

          # Uncomment the following to re-generate the image if needed (e.g. background image changes, text changes, etc)
          # File.open("#{RAILS_ROOT}/test/assets/banner_ads/generated_320x50.png", 'w') { |f| f.write(response.body) }

          # To diagnose a mismatch, uncomment the following and compare the new image to #{RAILS_ROOT}/test/assets/banner_ads/generated_320x50.png
          # File.open("#{RAILS_ROOT}/test/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

          ### The test seems to be failing due to different versions of ImageMagick / different fonts on other developer machines ###
          # assert(@generated_banner == response.body)
        end
      end
    end

    context "when calling 'index'" do
       context "with custom ad" do
         setup do
           @offer.banner_creatives = %w(320x50 640x100)
           @offer.rewarded = false
         end

         should "return proper image data in json" do
           aws_sdk_object = AWS::S3::S3Object.new(@aws_sdk_bucket, @offer.banner_creative_path('320x50'))
           custom_banner = File.read("#{RAILS_ROOT}/test/assets/banner_ads/custom_320x50.png")
           aws_sdk_object.stubs(:read).returns(custom_banner)
           objects = { @offer.banner_creative_path('320x50') => aws_sdk_object }
           @aws_sdk_bucket.stubs(:objects).returns(objects)

           response = get(:index, @params.merge(:format => 'json'))
           assert_equal('application/json', response.content_type)

           # To diagnose a mismatch, uncomment the following and compare the new image to #{RAILS_ROOT}/test/assets/banner_ads/custom_320x50.png
           # File.open("#{RAILS_ROOT}/test/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

           assert(custom_banner == Base64.decode64(assigns['image']))
         end

         should "return proper image data in xml" do
           aws_sdk_object = AWS::S3::S3Object.new(@aws_sdk_bucket, @offer.banner_creative_path('640x100'))
           custom_banner = File.read("#{RAILS_ROOT}/test/assets/banner_ads/custom_640x100.png")
           aws_sdk_object.stubs(:read).returns(custom_banner)
           objects = { @offer.banner_creative_path('640x100') => aws_sdk_object }
           @aws_sdk_bucket.stubs(:objects).returns(objects)

           response = get(:index, @params)
           assert_equal('application/xml', response.content_type)

           # To diagnose a mismatch, uncomment the following and compare the new image to #{RAILS_ROOT}/test/assets/banner_ads/custom_640x100.png
           # File.open("#{RAILS_ROOT}/test/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

           assert(custom_banner == Base64.decode64(assigns['image']))
         end
       end

       context "with generated ad" do
         setup do
           td_icon = File.read("#{RAILS_ROOT}/test/assets/icons/tap_defense.jpg")
           round_mask = File.read("#{RAILS_ROOT}/test/assets/display/round_mask.png")
           icon_shadow = File.read("#{RAILS_ROOT}/test/assets/display/icon_shadow.png")

           @right_aws_bucket.stubs(:get).with("icons/src/#{Offer.hashed_icon_id(@offer.icon_id)}.jpg").returns(td_icon)
           @right_aws_bucket.stubs(:get).with("display/round_mask.png").returns(round_mask)
           @right_aws_bucket.stubs(:get).with("display/icon_shadow.png").returns(icon_shadow)
         end

         should "return proper image data in json" do
           ad_bg = File.read("#{RAILS_ROOT}/test/assets/display/self_ad_bg_320x50.png")
           @right_aws_bucket.stubs(:get).with("display/self_ad_bg_320x50.png").returns(ad_bg)

           response = get(:index, @params.merge(:format => 'json'))
           assert_equal('application/json', response.content_type)

           # Uncomment the following to re-generate the image if needed (e.g. background image changes, text changes, etc)
           # File.open("#{RAILS_ROOT}/test/assets/banner_ads/generated_320x50.png", 'w') { |f| f.write(Base64.decode64(assigns['image'])) }

           # To diagnose a mismatch, uncomment the following and compare the new image to #{RAILS_ROOT}/test/assets/banner_ads/generated_320x50.png
           # File.open("#{RAILS_ROOT}/test/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

           ### The test seems to be failing due to different versions of ImageMagick / different fonts on other developer machines ###
           # assert(File.read("#{RAILS_ROOT}/test/assets/banner_ads/generated_320x50.png") == Base64.decode64(assigns['image']))
         end

         should "return proper image data in xml" do
           ad_bg = File.read("#{RAILS_ROOT}/test/assets/display/self_ad_bg_640x100.png")
           @right_aws_bucket.stubs(:get).with("display/self_ad_bg_640x100.png").returns(ad_bg)

           response = get(:index, @params)
           assert_equal('application/xml', response.content_type)

           # Uncomment the following to re-generate the image if needed (e.g. background image changes, text changes, etc)
           # File.open("#{RAILS_ROOT}/test/assets/banner_ads/generated_640x100.png", 'w') { |f| f.write(Base64.decode64(assigns['image'])) }

           # To diagnose a mismatch, uncomment the following and compare the new image to #{RAILS_ROOT}/test/assets/banner_ads/generated_640x100.png
           # File.open("#{RAILS_ROOT}/test/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

           ### The test seems to be failing due to different versions of ImageMagick / different fonts on other developer machines ###
           # assert(File.read("#{RAILS_ROOT}/test/assets/banner_ads/generated_640x100.png") == Base64.decode64(assigns['image']))
         end
       end
     end

     context "when calling 'webview'" do
       context "with custom ad" do
         setup do
            @offer.banner_creatives = %w(320x50)
            @offer.rewarded = false
          end

         should "contain proper image link" do
           response = get(:webview, @params)

           assert_match(/^#{CLOUDFRONT_URL}/, assigns['image_url'])
           assert_equal(@offer.display_ad_image_url(@currency.app.id, 320, 50, @currency.id), assigns['image_url'])
         end
       end

       context "with generated ad" do
         should "contain proper image link" do
           response = get(:webview, @params)

           assert_match(/^#{API_URL}/, assigns['image_url'])
           assert_equal(@offer.display_ad_image_url(@currency.app.id, 320, 50, @currency.id), assigns['image_url'])
         end
       end
     end
  end
end
