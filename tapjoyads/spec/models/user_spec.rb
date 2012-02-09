require 'spec_helper'

describe User do
  subject { Factory(:user) }

  describe '.has_many' do
    it { should have_many(:role_assignments) }
    it { should have_many(:partner_assignments) }
    it { should have_many(:user_roles).through(:role_assignments) }
    it { should have_many(:partners).through(:partner_assignments) }
  end

  describe '.belongs_to' do
    it { should belong_to(:current_partner) }
  end

  describe '#valid?' do
    it { should validate_uniqueness_of(:username) }
  end

  context 'A regular User' do
    before :each do
      @user = Factory(:user)
    end

    it 'has the partner role' do
      roles = @user.role_symbols
      roles.should include(:partner)
    end
  end

  context 'An admin User' do
    before :each do
      @admin = Factory(:admin)
    end

    it 'has the partner role and the admin role' do
      roles = @admin.role_symbols
      roles.should include(:partner)
      roles.should include(:admin)
    end
  end

end
