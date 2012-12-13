require 'spec_helper'

describe ConversionRate do
  it { should belong_to(:currency) }
  describe "#save" do
    let(:conversion) { FactoryGirl.build(:conversion_rate) }

    it "should cache the currency" do
      Currency.any_instance.should_receive(:cache)
      conversion.save
    end
  end
end
