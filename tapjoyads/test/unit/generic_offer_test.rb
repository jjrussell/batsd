require 'test_helper'

class GenericOfferTest < ActiveSupport::TestCase
  subject { Factory(:generic_offer) }

  should have_many(:offers)
  should have_one(:primary_offer)
  should belong_to(:partner)

  should validate_presence_of(:partner)
  should validate_presence_of(:name)
  should validate_presence_of(:url)

  # Test category validation
  context "A generic offer" do
    setup do
      @generic_offer = Factory(:generic_offer)
    end

    should "should accept a blank category" do
      @generic_offer.category = ""
      assert @generic_offer.valid?
    end

    should "should accept existing categories" do
      GenericOffer::CATEGORIES.each do |category|
        @generic_offer.category = category
        assert @generic_offer.valid?
      end
    end

    should "should reject invalid categories" do
      @generic_offer.category = "invalid"
      assert !@generic_offer.valid?
    end
  end
end
