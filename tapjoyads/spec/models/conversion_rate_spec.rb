require 'spec_helper'

describe ConversionRate do
  def with_attrs(attrs = {})
    FactoryGirl.build(:conversion_rate, attrs)
  end

  it { should belong_to(:currency) }

  describe '#save' do
    let(:currency) { FactoryGirl.create(:currency, :conversion_rate => 10) }
    let(:conversion) { with_attrs(:currency_id => currency.id, :rate => 40, :minimum_offerwall_bid => 3) }

    it "should cache the currency" do
      Currency.any_instance.should_receive(:cache)
      conversion.save
    end
  end

  describe 'validations' do
    context 'rate' do
      context 'when blank' do
        let(:subject) { with_attrs(:rate => nil) }
        it('should have errors') { should have(2).errors_on(:rate) }
      end

      context 'when <= 0' do
        let(:subject) { with_attrs(:rate => -1) }
        it('should have error') { should have(1).errors_on(:rate) }
      end
    end

    context 'minimum_offerwall_bid' do
      context 'when blank' do
        let(:subject) { with_attrs(:minimum_offerwall_bid => nil) }
        it('should have errors') { should have(2).errors_on(:minimum_offerwall_bid) }
      end

      context 'when <= 0' do
        let(:subject) { with_attrs(:minimum_offerwall_bid => -1) }
        it('should have error') { should have(1).errors_on(:minimum_offerwall_bid) }
      end
    end

    context 'currency_id' do
      context 'not unique rate scope' do
        let(:currency) { FactoryGirl.create(:currency, :conversion_rate => 1) }
        let(:conversion_rate) { FactoryGirl.create(:conversion_rate, :currency_id => currency.id, :rate => 9, :minimum_offerwall_bid => 10) }
        let(:subject) { with_attrs(:currency_id => conversion_rate.currency_id, :rate => conversion_rate.rate, :minimum_offerwall_bid => 15) }
        it('should not be valid') { should_not be_valid }
        it('should have error') { should have(1).errors_on(:currency_id) }
      end

      context 'not unique minimum offerwall bid scope' do
        let(:currency) { FactoryGirl.create(:currency, :conversion_rate => 1) }
        let(:conversion_rate) { FactoryGirl.create(:conversion_rate, :currency_id => currency.id, :rate => 9, :minimum_offerwall_bid => 10) }
        let(:subject) { with_attrs(:currency_id => conversion_rate.currency_id, :rate => 25, :minimum_offerwall_bid => conversion_rate.minimum_offerwall_bid) }
        it('should not be valid') { should_not be_valid }
        it('should have error') { should have(1).errors_on(:currency_id) }
      end
    end
  end

  describe '#necessary_conversion_rate' do
    context '#invalid_rate?' do
      context 'has an invalid rate' do
        let(:currency) { FactoryGirl.create(:currency, :conversion_rate => 1) }
        let(:subject) { with_attrs(:currency_id => currency.id, :rate => 0.5) }
        it { should be_invalid_rate }
      end

      context 'has a valid rate' do
        let(:currency) { FactoryGirl.create(:currency, :conversion_rate => 1) }
        let(:subject) { with_attrs(:currency_id => currency.id, :rate => 15) }
        it { should_not be_invalid_rate }
      end
    end

    context '#outside_bounds?' do
      context 'invalid' do
        let(:currency) { FactoryGirl.create(:currency, :conversion_rate => 1) }
        let(:conversion_rate) { FactoryGirl.create(:conversion_rate, :rate => 5, :minimum_offerwall_bid => 5, :currency_id => currency.id) }
        let(:subject) { with_attrs(:currency_id => conversion_rate.currency_id, :rate => 4, :minimum_offerwall_bid => 10) }
        it { should be_outside_bounds(conversion_rate) }
      end

      context 'valid' do
        let(:currency) { FactoryGirl.create(:currency, :conversion_rate => 1) }
        let(:conversion_rate) { FactoryGirl.create(:conversion_rate, :rate => 5, :minimum_offerwall_bid => 5, :currency_id => currency.id) }
        let(:subject) { with_attrs(:currency_id => conversion_rate.currency_id, :rate => 6, :minimum_offerwall_bid => 10) }
        it { should_not be_outside_bounds(conversion_rate) }
      end
    end

    context '#inside_bounds?' do
      context 'invalid' do
        let(:currency) { FactoryGirl.create(:currency, :conversion_rate => 1) }
        let(:conversion_rate) { FactoryGirl.create(:conversion_rate, :rate => 5, :minimum_offerwall_bid => 5, :currency_id => currency.id) }
        let(:subject) { with_attrs(:currency_id => conversion_rate.currency_id, :rate => 6, :minimum_offerwall_bid => 4) }
        it { should be_inside_bounds(conversion_rate) }
      end

      context 'valid' do
        let(:currency) { FactoryGirl.create(:currency, :conversion_rate => 1) }
        let(:conversion_rate) { FactoryGirl.create(:conversion_rate, :rate => 5, :minimum_offerwall_bid => 5, :currency_id => currency.id) }
        let(:subject) { with_attrs(:currency_id => conversion_rate.currency_id, :rate => 200, :minimum_offerwall_bid => 10) }
        it { should_not be_inside_bounds(conversion_rate) }
      end
    end
  end
end
