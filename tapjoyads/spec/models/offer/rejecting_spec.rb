require 'spec_helper'

describe Offer::Rejecting do
  before :each do
    @dummy_class = Object.new
    @dummy_class.extend(Offer::Rejecting)
  end
  describe '#has_insufficient_funds?' do
    before :each do
      @currency = FactoryGirl.create(:currency)
    end
    context 'charges > 0' do
      before :each do
        @dummy_class.stub(:partner_id).and_return('partner_id')
        @dummy_class.stub(:payment).and_return(30)
      end
      context 'balance > 0' do
        before :each do
          @dummy_class.stub(:partner_balance).and_return(30)
        end
        subject { @dummy_class }
        it { should_not have_insufficient_funds(@currency) }
      end
      context 'balance <= 0' do
        before :each do
          @dummy_class.stub(:partner_balance).and_return(0)
        end
        subject { @dummy_class }
        it { should have_insufficient_funds(@currency) }
      end
    end
    context 'charges <= 0' do
      before :each do
        @dummy_class.stub(:partner_id).and_return(@currency.partner_id)
      end
      context 'balance > 0' do
        before :each do
          @dummy_class.stub(:partner_balance).and_return(30)
        end
        subject { @dummy_class }
        it { should_not have_insufficient_funds(@currency) }
      end
      context 'balance <= 0' do
        before :each do
          @dummy_class.stub(:partner_balance).and_return(0)
        end
        subject { @dummy_class }
        it { should_not have_insufficient_funds(@currency) }
      end
    end
  end
end
