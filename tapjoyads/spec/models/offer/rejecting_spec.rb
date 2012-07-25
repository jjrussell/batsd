require 'spec_helper'

class DummyClass
end

describe Offer::Rejecting do
  before :each do
    @dummy_class = DummyClass.new
    @dummy_class.extend(Offer::Rejecting)
  end
  describe 'has_no_partner_funds?' do
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
        it { should_not have_no_partner_funds(@currency) }
      end
      context 'balance <= 0' do
        before :each do
          @dummy_class.stub(:partner_balance).and_return(0)
        end
        subject { @dummy_class }
        it { should have_no_partner_funds(@currency) }
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
        it { should_not have_no_partner_funds(@currency) }
      end
      context 'balance <= 0' do
        before :each do
          @dummy_class.stub(:partner_balance).and_return(0)
        end
        subject { @dummy_class }
        it { should_not have_no_partner_funds(@currency) }
      end
    end
  end
end
