require 'test_helper'

class RatingOfferTest < ActiveSupport::TestCase
  subject { Factory(:rating_offer) }

  should have_many(:offers)
  should have_one(:primary_offer)
  should belong_to(:partner)
  should belong_to(:app)

  should validate_presence_of(:partner)

  context "A RatingOffer" do
    setup do
      @rating_offer = Factory(:rating_offer)
    end

    should "append the app version to the id" do
      assert_equal "#{@rating_offer.id}", @rating_offer.get_id_with_app_version(nil)
      assert_equal "#{@rating_offer.id}.1.0", @rating_offer.get_id_with_app_version('1.0')
    end
  end
end
