require 'spec_helper'

describe UserRole do

  subject { Factory(:user_role) }

  describe '#valid?' do
    it { should validate_uniqueness_of(:name) }
  end

end
