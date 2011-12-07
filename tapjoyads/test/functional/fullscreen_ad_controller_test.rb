require 'test_helper'

class FullscreenAdControllerTest < ActionController::TestCase

  context "hitting fullscreen ad controller" do
    setup do
      RailsCache.stubs(:get).returns(nil)
      @offer = Factory(:app).primary_offer
      @offer.name = "Consistent Name"
      Offer.stubs(:find_in_cache).with(@offer.id).returns(@offer)
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])

      @currency = Factory(:currency)
      @params = { :udid => 'stuff', :publisher_user_id => 'more_stuff', :currency_id => @currency.id, :app_id => @currency.app.id }
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

          assert response.body.include? '>x</div>'
        end

        context "when offer is rewarded" do
          should "include call-to-action button with specific reward text" do
            response = get :index, @params
            assert_response :success
            assert response.body.include? "Earn #{@currency.get_visual_reward_amount(@offer)} #{@currency.name}</a>"
          end
        end

        context "when offer is non-rewarded" do
          setup do
            @offer.rewarded = false
          end

          should "include call-to-action button with specific reward text" do
            response = get :index, @params
            assert_response :success
            assert response.body.include? 'Download</a>'
          end
        end
      end

      context "with generated ad" do
        should "render generated ad template" do
          get :index, @params
          assert_response :success
          assert_template "fullscreen_ad/index"
        end
      end
    end
  end
end
