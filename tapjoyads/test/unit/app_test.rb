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
      @app = Factory(:app)
      @app.app_metadatas << Factory(:app_metadata, :price => 200)
      @app.save!
    end
    should "update its offers' bids when its price changes" do
      offer = @app.primary_offer
      current_offer_bid = offer.bid
      @app.primary_app_metadata.update_attributes({:price => 400})
      offer.reload
      assert_equal 200, offer.bid
      assert_equal 400, offer.price
    end
  end

  context "An App with Action Offers" do
    setup do
      @action_offer = Factory(:action_offer)
      @app = @action_offer.app
      @app_metadata = Factory(:app_metadata, :price => 200)
      @app.app_metadatas << @app_metadata
    end

    should "update action offer hidden field" do
      @app.update_attributes({:hidden => true})
      @action_offer.reload
      offer = @action_offer.primary_offer
      assert @action_offer.hidden?
      assert !offer.tapjoy_enabled?
    end

    should "update action offer bids when its price changes" do
      @app_metadata.update_attributes({:price => 400})
      @action_offer.reload
      offer = @action_offer.primary_offer
      assert_equal 200, offer.bid
      assert_equal 400, offer.price
    end

    should "not update action offer bids if has prerequisite offer" do
      @action_offer.prerequisite_offer = @app.primary_offer
      @action_offer.save
      offer = @action_offer.primary_offer
      current_offer_bid = offer.bid
      @app_metadata.update_attributes({:price => 450})
      offer.reload
      assert_equal 35, offer.bid
    end
  end
end
