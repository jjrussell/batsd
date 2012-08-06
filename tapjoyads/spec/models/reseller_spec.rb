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

  %w(pending_earnings next_payout_amount).each do |attribute|
    describe "\##{attribute}" do
      it "reads the '#{attribute}' attribute" do
        subject.should_receive(:read_attribute).with(attribute)
        subject.send(attribute.to_sym)
      end

      it 'coerces the attribute to a float' do
        response = '1.0'
        response.should_receive(:to_f)
        subject.stub(:read_attribute => response)
        subject.send(attribute.to_sym)
      end
    end
  end
end
