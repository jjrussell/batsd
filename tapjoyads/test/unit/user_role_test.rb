require 'test_helper'

class UserRoleTest < ActiveSupport::TestCase
  subject { Factory(:user_role) }

  should validate_uniqueness_of(:name)
end
