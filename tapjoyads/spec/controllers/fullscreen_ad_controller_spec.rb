require 'spec/spec_helper'

describe FullscreenAdController do
  integrate_views

  describe "hitting fullscreen ad controller" do
    before :each do
      RailsCache.stubs(:get).returns(nil)
      @offer = Factory(:app).primary_offer
      @offer.name = "Consistent Name"
      Offer.stubs(:find_in_cache).with(@offer.id).returns(@offer)
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])

      @currency = Factory(:currency)
      @params = { :udid => 'stuff', :publisher_user_id => 'more_stuff', :currency_id => @currency.id, :app_id => @currency.app.id }
    end

    describe "when calling 'index'" do
      before :each do
        @params.merge! :offer_id => @offer.id, :image_size => '320x480', :publisher_app_id => @params[:app_id]
        @params.delete :app_id
      end

      describe "with custom ads" do
        before :each do
          @offer.banner_creatives = %w(320x480 480x320)
          @offer.featured = true
        end

        it "should render custom creative template" do
          get :index, @params

          response.should be_success
          response.should render_template("fullscreen_ad/custom_creative")
          response.should have_tag('div', 'x')
        end

        describe "when offer is rewarded" do
          it "should include call-to-action button with specific reward text" do
            get :index, @params

            expected_text = "Earn #{@currency.get_visual_reward_amount(@offer)} #{@currency.name}"
            response.should be_success
            response.should have_tag('a', expected_text)
          end
        end

        describe "when offer is non-rewarded" do
          before :each do
            @offer.rewarded = false
          end

          it "should include call-to-action button with specific reward text" do
            get :index, @params

            response.should be_success
            response.should have_tag('a', 'Download')
          end
        end
      end

      describe "with generated ad" do
        it "should render generated ad template" do
          get :index, @params

          response.should be_success
          response.should render_template("fullscreen_ad/index")
        end
      end
    end
  end
end
