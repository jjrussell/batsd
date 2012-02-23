require 'spec_helper'

describe EnableOfferRequest do

  describe '.belongs_to' do
    it { should belong_to(:offer) }
    it { should belong_to(:assigned_to) }
  end

  before :each do
    @enable_offer_request = Factory(:enable_offer_request)
    @user = Factory(:user)
    @account_mgr = Factory(:account_mgr_user)
  end

  it "allows account managers to be assignees" do
    @enable_offer_request.assigned_to = @account_mgr
    @enable_offer_request.should be_valid
  end

  it "does not allow non-account managers to be assignees" do
    @enable_offer_request.assigned_to = @user
    @enable_offer_request.should_not be_valid
  end

  it "allows status between 0 and 3" do
    (0..3).each do |status|
      @enable_offer_request.status = status
      @enable_offer_request.should be_valid
    end
    @enable_offer_request.status = -1
    @enable_offer_request.should_not be_valid
    @enable_offer_request.status = 4
    @enable_offer_request.should_not be_valid
  end

  it "is not approved with archived apps" do
    app = @enable_offer_request.offer.item
    app.hidden = true
    app.save

    @enable_offer_request.reload
    @enable_offer_request.status = EnableOfferRequest::STATUS_APPROVED
    @enable_offer_request.should_not be_valid
  end
end
