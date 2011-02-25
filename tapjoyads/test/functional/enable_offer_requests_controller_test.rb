require 'test_helper'

class EnableOfferRequestsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  context "Users wishing to tapjoy-enable offers" do
    setup do
      @user = Factory(:user)
      @partner = Factory(:partner, :users => [@user])
      @app = Factory(:app, :partner => @partner)
      @offer = @app.primary_offer
      login_as(@user)
    end

    should "be able to submit a request" do
      assert_equal 0, @offer.enable_offer_requests.count
      post :create, :enable_offer_request => { :offer_id => @offer.id }
      assert_response(:redirect)
      assert_equal 0, @offer.enable_offer_requests.first.status
    end
  end
end
