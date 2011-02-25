require 'test_helper'

class EnableOfferRequestTest < ActiveSupport::TestCase
  should belong_to(:offer)
  should belong_to(:assigned_to)

  context "EnableOfferRequest" do
    setup do
      @enable_offer_request = Factory(:enable_offer_request)
      @user = Factory(:user)
      @account_mgr = Factory(:account_mgr_user)
    end

    should "allow account managers to be assignees" do
      @enable_offer_request.assigned_to = @account_mgr
      assert @enable_offer_request.valid?
    end

    should "not allow non-account managers to be assignees" do
      @enable_offer_request.assigned_to = @user
      assert !@enable_offer_request.valid?
    end

    should "allow status between 0 and 3" do
      (0..3).each do |status|
        @enable_offer_request.status = status
        assert @enable_offer_request.valid?
      end
      @enable_offer_request.status = -1
      assert !@enable_offer_request.valid?
      @enable_offer_request.status = 4
      assert !@enable_offer_request.valid?
    end
  end
end
