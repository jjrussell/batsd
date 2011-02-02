require 'test_helper'

class ActionOfferTest < ActiveSupport::TestCase
  subject { Factory :action_offer }
  
  should have_many :offers
  should have_one :primary_offer
  should belong_to :partner
  should belong_to :app
  
  should validate_presence_of :partner
  should validate_presence_of :app
  should validate_presence_of :instructions
  
  should "accept nested attributes for primary_offer" do
    assert_respond_to subject, :primary_offer_attributes=
  end
  
  should "delgate user_enabled?, tapjoy_enabled?, bid, description, min_bid, and daily_budget to primary_offer" do
    delegated_methods = [ :user_enabled?, :tapjoy_enabled?, :bid, :description, :min_bid, :daily_budget ]
    delegated_methods.each do |dm|
      assert_respond_to subject, dm
    end
  end
  
  context "ActionOffer when updated" do
    setup do
      subject.name = "this is a new name"
      subject.save!
    end
    
    should "update its associated Offers" do
      subject.offers.each do |offer|
        assert_equal "this is a new name", offer.name
      end
    end
  end
  
end
