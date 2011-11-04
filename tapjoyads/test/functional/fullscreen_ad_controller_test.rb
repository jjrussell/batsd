require 'test_helper'

##
## RESTRUCTURE THIS TEST TO TEST ADS BOTH WITH AND WITHOUT CURRENCY
##

class FullscreenAdControllerTest < ActionController::TestCase

  context "hitting fullscreen ad controller with app with virtual currency" do
    setup do
      RailsCache.stubs(:get).returns(nil)
      @offer = Factory(:app).primary_offer
      @offer.name = "Consistent Name"
      Offer.stubs(:find_in_cache).with(@offer.id).returns(@offer)
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])

      @currency = Factory(:currency)
      @params = { :udid => 'stuff', :publisher_user_id => 'more_stuff', :currency_id => @currency.id, :app_id => @currency.app.id }
    end

    context "when calling 'image'" do
      setup do
        @params.merge! :offer_id => @offer.id, :image_size => '320x480', :publisher_app_id => @params[:app_id], :preview => true
        @params.delete :app_id
      end

      context "with custom ad" do
        setup do
          @offer.banner_creatives = %w(320x480)
          @offer.featured = true
        end

        should "return PNG preview image" do
          response = get :image, @params
          assert_response :success
          assert_equal 'image/png', response.content_type
        end
      end

      context "with generated ad" do
        should "return preview PNG image" do
          response = get :image, @params
          assert_response :success
          assert_equal 'image/png', response.content_type
        end
      end
    end

    context "when calling 'index'" do
      setup do
        @params.merge! :offer_id => @offer.id, :image_size => '320x480', :publisher_app_id => @params[:app_id]
        @params.delete :app_id
      end

      context "with custom ads" do
        setup do
          @offer.banner_creatives = %w(320x480 480x320)
          @offer.featured = true
        end

        should "render custom creative template" do
          response = get :index, @params
          assert_response :success
          assert_template "fullscreen_ad/custom_creative"

          assert response.body.include? 'Skip'
          assert response.body.include? "Earn #{@currency.get_visual_reward_amount(@offer, params[:display_multiplier])} #{@currency.name}"
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
