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
end
