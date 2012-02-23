require 'spec_helper'

describe Reseller do
  describe '.has_many' do
    it { should have_many :users }
    it { should have_many :partners }
    it { should have_many :currencies }
    it { should have_many :offers }
  end

  describe '#valid?' do
    it { should validate_presence_of :name }
    it { should validate_numericality_of :rev_share }
    it { should validate_numericality_of :reseller_rev_share }
  end
end
