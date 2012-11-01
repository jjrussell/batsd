require 'spec_helper'

describe CurrencySale do
  it { should belong_to(:currency) }

  describe '#past?' do
    before :each do
      @currency = FactoryGirl.create(:currency)
    end
    context 'in the past' do
      before :each do
        @currency_sale = FactoryGirl.build(:currency_sale, :currency_id => @currency.id, :start_time => 4.days.ago, :end_time => 3.days.ago)
      end
      it 'should return true' do
        @currency_sale.past?.should be_true
      end
    end
    context 'not in the past' do
      before :each do
        @currency_sale = FactoryGirl.build(:currency_sale, :currency_id => @currency.id)
      end
      it 'should return true' do
        @currency_sale.past?.should be_false
      end
    end
  end
end
