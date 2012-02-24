require 'spec_helper'

describe RoleAssignment do
  describe '#<=>' do
    before :each do
      user = Factory(:user)
      5.times { user.user_roles << Factory(:user_role) }
      @assignments = user.role_assignments
    end

    it 'should sort based on name' do
      sorted = @assignments.sort
      names = @assignments.map(&:name)
      sorted.map(&:name).should == names.sort
    end
  end
end
