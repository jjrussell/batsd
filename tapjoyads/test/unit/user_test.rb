require 'test_helper'

class UserTest < ActiveSupport::TestCase
  subject { Factory(:user) }

  should have_many(:role_assignments)
  should have_many(:partner_assignments)
  should have_many(:user_roles).through(:role_assignments)
  should have_many(:partners).through(:partner_assignments)
  should belong_to(:current_partner)

  should validate_uniqueness_of(:username)

  context "A regular User" do
    setup do
      @user = Factory(:user)
    end

    should "have the partner role" do
      roles = @user.role_symbols
      assert roles.include?(:partner)
    end
  end

  context "An admin User" do
    setup do
      @admin = Factory(:admin)
    end

    should "have the partner role and the admin role" do
      roles = @admin.role_symbols
      assert roles.include?(:partner)
      assert roles.include?(:admin)
    end
  end

end
