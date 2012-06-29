require 'spec_helper'

describe PartnerAssignment do
  describe '#<=>' do
    before :each do
      user = FactoryGirl.create(:user)
      5.times { user.partners << FactoryGirl.create(:partner) }
      @assignments = user.partner_assignments
    end

    it 'should sort based on name' do
      sorted = @assignments.sort
      names = @assignments.map(&:name)
      sorted.map(&:name).should == names.sort
    end
  end
end
