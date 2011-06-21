require 'test_helper'

class GamerTest < ActiveSupport::TestCase
  subject { Factory(:user) }
  
  should validate_uniqueness_of(:username)
end
