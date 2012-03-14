require 'spec_helper'

describe EarningsAdjustment do

  subject { Factory(:earnings_adjustment) }

  describe '.belongs_to' do
    it { should belong_to(:partner) }
  end

  describe '#valid?' do
    it { should validate_presence_of(:partner) }
    it { should validate_presence_of(:notes) }
    it { should validate_numericality_of(:amount) }
  end

end
