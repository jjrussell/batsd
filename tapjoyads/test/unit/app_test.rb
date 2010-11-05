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
  
  
end
