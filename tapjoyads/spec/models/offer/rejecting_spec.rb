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

  describe '#has_coupon_already_pending?' do
    before :each do
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.extend(Offer::Rejecting)
    end
    context 'no pending coupon for offer' do
      before :each do
        @device = FactoryGirl.create(:device)
      end
      it 'should return false' do
        @offer.has_coupon_already_pending?(@device).should == false
      end
    end
    context 'a nil device' do
      it 'should return false' do
        @offer.has_coupon_already_pending?(nil).should == false
      end
    end
    context 'there is a pending coupon for offer' do
      before :each do
        @offer.item_type = 'Coupon'
        @device = FactoryGirl.create(:device)
        @device.set_pending_coupon(@offer.id)
      end
      it 'should return true' do
        @offer.has_coupon_already_pending?(@device).should == true
      end
    end
  end

  describe '#has_coupon_offer_not_started?' do
    before :each do
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.item_type = 'Coupon'
      @offer.extend(Offer::Rejecting)
    end
    context 'coupon offer has started' do
      before :each do
        @coupon = FactoryGirl.create(:coupon)
        @offer.item_id = @coupon.id
      end
      subject { @offer }
      it { should_not have_coupon_offer_not_started }
    end
    context 'coupon offer has started' do
      before :each do
        @coupon = FactoryGirl.create(:coupon, :start_date => Date.today + 2.days)
        @offer.item_id = @coupon.id
      end
      subject { @offer }
      it { should have_coupon_offer_not_started }
    end
  end

  describe '#has_coupon_offer_expired?' do
    before :each do
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.item_type = 'Coupon'
      @offer.extend(Offer::Rejecting)
    end
    context 'coupon offer has expired' do
      before :each do
        @coupon = FactoryGirl.create(:coupon, :end_date => Date.today)
        @offer.item_id = @coupon.id
      end
      subject { @offer }
      it { should have_coupon_offer_expired }
    end
    context 'coupon offer has not expired' do
      before :each do
        @coupon = FactoryGirl.create(:coupon)
        @offer.item_id = @coupon.id
      end
      subject { @offer }
      it { should_not have_coupon_offer_expired }
    end
  end
end
