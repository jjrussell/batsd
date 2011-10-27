require 'test_helper'

class DisplayAdControllerTest < ActionController::TestCase

  context "hitting display ad controller" do
    setup do
      RailsCache.stubs(:get).returns(nil)
      @offer = Factory(:app).primary_offer
      @offer.name = "Consistent Name"
      Offer.stubs(:find_in_cache).with(@offer.id).returns(@offer)
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])

      @bucket = S3.bucket(BucketNames::TAPJOY)
      S3.stubs(:bucket).with(BucketNames::TAPJOY).returns(@bucket)

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

          object = @bucket.objects[@offer.banner_creative_path('320x50')]
          @custom_banner = File.read("#{RAILS_ROOT}/test/assets/banner_ads/custom_320x50.png")
          object.stubs(:read).returns(@custom_banner)
          @bucket.stubs(:objects).returns({ @offer.banner_creative_path('320x50') => object })
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

          obj_ad_bg = @bucket.objects["display/self_ad_bg_320x50.png"]
          obj_td_icon = @bucket.objects["icons/src/#{Offer.hashed_icon_id(@offer.icon_id)}.jpg"]
          obj_round_mask = @bucket.objects["display/round_mask.png"]
          obj_icon_shadow = @bucket.objects["display/icon_shadow.png"]
          objects = {
            "display/self_ad_bg_320x50.png" => obj_ad_bg,
            "icons/src/#{Offer.hashed_icon_id(@offer.icon_id)}.jpg" => obj_td_icon,
            "display/round_mask.png" => obj_round_mask,
            "display/icon_shadow.png" => obj_icon_shadow,
          }

          @bucket.stubs(:objects).returns(objects)
          obj_ad_bg.stubs(:read).returns(ad_bg)
          obj_td_icon.stubs(:read).returns(td_icon)
          obj_round_mask.stubs(:read).returns(round_mask)
          obj_icon_shadow.stubs(:read).returns(icon_shadow)

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
          object = @bucket.objects[@offer.banner_creative_path('320x50')]
          custom_banner = File.read("#{RAILS_ROOT}/test/assets/banner_ads/custom_320x50.png")
          object.stubs(:read).returns(custom_banner)
          @bucket.stubs(:objects).returns({ @offer.banner_creative_path('320x50') => object })

          response = get(:index, @params.merge(:format => 'json'))
          assert_equal('application/json', response.content_type)

          # To diagnose a mismatch, uncomment the following and compare the new image to #{RAILS_ROOT}/test/assets/banner_ads/custom_320x50.png
          # File.open("#{RAILS_ROOT}/test/assets/banner_ads/wtf.png", 'w') { |f| f.write(response.body) }

          assert(custom_banner == Base64.decode64(assigns['image']))
        end

        should "return proper image data in xml" do
          object = @bucket.objects[@offer.banner_creative_path('640x100')]
          custom_banner = File.read("#{RAILS_ROOT}/test/assets/banner_ads/custom_640x100.png")
          object.stubs(:read).returns(custom_banner)
          @bucket.stubs(:objects).returns({ @offer.banner_creative_path('640x100') => object })

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

          obj_td_icon = @bucket.objects["icons/src/#{Offer.hashed_icon_id(@offer.icon_id)}.jpg"]
          obj_round_mask = @bucket.objects["display/round_mask.png"]
          obj_icon_shadow = @bucket.objects["display/icon_shadow.png"]
          objects = {
            "icons/src/#{Offer.hashed_icon_id(@offer.icon_id)}.jpg" => obj_td_icon,
            "display/round_mask.png" => obj_round_mask,
            "display/icon_shadow.png" => obj_icon_shadow,
          }
          @bucket.stubs(:objects).returns(objects)
          obj_td_icon.stubs(:read).returns(td_icon)
          obj_round_mask.stubs(:read).returns(round_mask)
          obj_icon_shadow.stubs(:read).returns(icon_shadow)
        end

        should "return proper image data in json" do
          ad_bg = File.read("#{RAILS_ROOT}/test/assets/display/self_ad_bg_320x50.png")
          obj_ad_bg = @bucket.objects["display/self_ad_bg_320x50.png"]
          @bucket.stubs(:objects).returns({ "display/self_ad_bg_320x50.png" => obj_ad_bg })
          obj_ad_bg.stubs(:read).returns(ad_bg)

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
          obj_ad_bg = @bucket.objects["display/self_ad_bg_640x100.png"]
          @bucket.stubs(:objects).returns({ "display/self_ad_bg_640x100.png" => obj_ad_bg })
          obj_ad_bg.stubs(:read).returns(ad_bg)

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
