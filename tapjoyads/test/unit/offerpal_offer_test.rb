require 'test_helper'

class OfferpalOfferTest < ActiveSupport::TestCase
  subject { Factory(:offerpal_offer) }

  should have_many(:offers)
  should have_one(:primary_offer)
  should belong_to(:partner)

  should validate_presence_of(:partner)
  should validate_presence_of(:name)
  should validate_presence_of(:offerpal_id)
  should validate_uniqueness_of(:offerpal_id)
end
