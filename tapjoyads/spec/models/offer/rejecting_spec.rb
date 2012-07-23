require 'spec_helper'
include Offer::Rejecting

module Offer::Rejecting
  describe Offer::Rejecting do
    describe 'partner_has_no_funds?' do
      before :each do
        @currency = FactoryGirl.create(:currency)
      end
      context 'charges > 0 and balance > 0' do
        before :each do
          Offer::Rejecting.stub(:partner_id).and_return('partner_id')
          Offer::Rejecting.stub(:payment).and_return(30)
          Offer::Rejecting.stub(:partner_balance).and_return(30)
        end
        it 'should return false' do
          Offer::Rejecting.partner_has_no_funds?(@currency).should == false
        end
      end
      context 'charges > 0 and balance <= 0' do
        before :each do
          Offer::Rejecting.stub(:partner_id).and_return('partner_id')
          Offer::Rejecting.stub(:payment).and_return(30)
          Offer::Rejecting.stub(:partner_balance).and_return(0)
        end
        it 'should return true' do
          Offer::Rejecting.partner_has_no_funds?(@currency).should == true
        end
      end
      context 'charges <= 0 and balance > 0' do
        before :each do
          Offer::Rejecting.stub(:partner_id).and_return(@currency.partner_id)
          Offer::Rejecting.stub(:partner_balance).and_return(30)
        end
        it 'should return false' do
          Offer::Rejecting.partner_has_no_funds?(@currency).should == false
        end
      end
      context 'charges <= 0 and balance <= 0' do
        before :each do
          Offer::Rejecting.stub(:partner_id).and_return(@currency.partner_id)
          Offer::Rejecting.stub(:partner_balance).and_return(0)
        end
        it 'should return false since they are not being charged and have no budget' do
          Offer::Rejecting.partner_has_no_funds?(@currency).should == false
        end
      end
    end
    describe 'not_charging_and_no_balance?' do
      before :each do
        @currency = FactoryGirl.create(:currency)
      end
      context 'charges > 0 and balance > 0' do
        before :each do
          Offer::Rejecting.stub(:partner_id).and_return('partner_id')
          Offer::Rejecting.stub(:payment).and_return(30)
          Offer::Rejecting.stub(:partner_balance).and_return(30)
        end
        it 'should return false' do
          Offer::Rejecting.not_charging_and_no_balance?(@currency).should == false
        end
      end
      context 'charges > 0 and balance <= 0' do
        before :each do
          Offer::Rejecting.stub(:partner_id).and_return('partner_id')
          Offer::Rejecting.stub(:payment).and_return(30)
          Offer::Rejecting.stub(:partner_balance).and_return(0)
        end
        it 'should return true' do
          Offer::Rejecting.not_charging_and_no_balance?(@currency).should == false
        end
      end
      context 'charges <= 0 and balance > 0' do
        before :each do
          Offer::Rejecting.stub(:partner_id).and_return(@currency.partner_id)
          Offer::Rejecting.stub(:partner_balance).and_return(30)
        end
        it 'should return false' do
          Offer::Rejecting.not_charging_and_no_balance?(@currency).should == false
        end
      end
      context 'charges <= 0 and balance <= 0' do
        before :each do
          Offer::Rejecting.stub(:partner_id).and_return(@currency.partner_id)
          Offer::Rejecting.stub(:partner_balance).and_return(0)
        end
        it 'should return false since they are not being charged and have no budget' do
          Offer::Rejecting.not_charging_and_no_balance?(@currency).should == true
        end
      end
    end
  end
end
