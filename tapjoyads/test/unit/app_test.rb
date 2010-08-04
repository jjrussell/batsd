require 'test_helper'

class AppTest < ActiveSupport::TestCase
  subject { Factory(:app) }
  
  should have_one(:offer)
  should have_one(:currency)
  should have_one(:rating_offer)
  should have_many(:publisher_conversions)
  should belong_to(:partner)
  
  should validate_presence_of(:partner)
  should validate_presence_of(:name)
  
  
end
