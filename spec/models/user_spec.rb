require 'spec_helper'

describe User do
  subject { FactoryGirl.create(:user) }

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

  it { should validate_presence_of(:time_zone) }

  describe '#role_symbols' do
    context 'given a regular user' do
      before :each do
        @user = FactoryGirl.create(:user)
      end

      it 'includes the partner role' do
        @user.role_symbols.should include(:partner)
      end
    end

    context 'given an admin user' do
      before :each do
        @admin = FactoryGirl.create(:user, :with_admin_role)
      end

      it 'has the partner role' do
        @admin.role_symbols.should include(:partner)
      end

      it 'includes the admin role' do
        @admin.role_symbols.should include(:admin)
      end
    end
  end
end
