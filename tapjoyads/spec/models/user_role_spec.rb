require 'spec_helper'

describe UserRole do

  subject { Factory(:user_role) }

  describe '#valid?' do
    it { should validate_uniqueness_of(:name) }
  end

  describe '#admin?' do
    context 'when name is admin' do
      it 'is true' do
        UserRole.find_or_create_by_name('admin').should be_admin
      end
    end

    context 'when name is not admin' do
      it 'is not true' do
        @not_admin = Factory(:user_role).should_not be_admin
      end
    end
  end
end
