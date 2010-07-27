require 'test_helper'

class EmailOfferTest < ActiveSupport::TestCase
  subject { Factory(:email_offer) }
  
  should have_one(:offer)
  should belong_to(:partner)
  
  should validate_presence_of(:partner)
  should validate_presence_of(:name)
end
