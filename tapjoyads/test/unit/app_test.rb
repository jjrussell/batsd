require 'test_helper'

class AppTest < ActiveSupport::TestCase
  subject { Factory(:app) }
  
  should have_many(:offers)
  should have_one(:primary_offer)
  should have_many(:currencies)
  should have_one(:primary_currency)
  should have_one(:rating_offer)
  should have_many(:publisher_conversions)
  should belong_to(:partner)
  
  should validate_presence_of(:partner)
  should validate_presence_of(:name)
  
  context "An App" do
    setup do
      @app = Factory(:app, :price => 200)
    end
    
    should "update its offers' bids when its price changes" do
      @offer = @app.primary_offer
      @current_offer_bid = @offer.bid
      @app.update_attribute(:price, 400)
      @offer.reload
      assert_equal 200, @offer.bid
    end
  end
  
end
