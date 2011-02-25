require 'test_helper'

class OffersControllerTest < ActionController::TestCase
  setup :activate_authlogic
  setup do
  end

  context "Users wishing to tapjoy-enable offers" do
    setup do
      @user = Factory(:user)
      @partner = Factory(:partner, :users => [@user])
      @app = Factory(:app, :partner => @partner)
      @offer = @app.primary_offer
      login_as(@user)
      @controller = Apps::OffersController.new
    end

    should "be able to submit a request" do
      post 'request_tapjoy_enable', :app_id => @app.id, :id => @offer.id
      assert_response(:redirect)
      assert_equal 0, @offer.enable_offer_requests.first.status
      assert_equal 'request_tapjoy_enable', assigns['activity_logs'].last.action
      assert_equal 'EnableOfferRequest', assigns['activity_logs'].last.object_type
      assert_equal @offer.enable_offer_requests.first.id.to_s, assigns['activity_logs'].last.object_id
    end
  end
end
