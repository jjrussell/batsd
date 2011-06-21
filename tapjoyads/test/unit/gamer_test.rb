require 'test_helper'

class GamerTest < ActiveSupport::TestCase
  subject { Factory(:user) }
  
  should validate_uniqueness_of(:username)
  should validate_uniqueness_of(:email)
end
