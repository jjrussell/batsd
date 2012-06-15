require 'spec_helper'

describe Order do

  before :each do
    @order = FactoryGirl.create(:order)
  end

  describe '.belongs_to' do
    it { should belong_to :partner }
  end

  describe '#valid?' do
    it { should validate_presence_of :partner }
    it { should validate_presence_of :note }
    it { should validate_numericality_of :amount }
    it { should ensure_inclusion_of(:status).in_range(Order::STATUS_CODES.keys) }
    it { should ensure_inclusion_of(:payment_method).in_range(Order::PAYMENT_METHODS.keys.sort) }
  end

  describe 'an invoice' do
    it 'is created if the client exists in freshbooks' do
      FreshBooks.should_receive(:get_client_id).and_return(5)
      FreshBooks.should_receive(:create_invoice).and_return(7)

      @order.status.should == 1
      @order.invoice_id.should == nil
      @order.freshbooks_client_id.should == nil

      @order.create_freshbooks_invoice!

      @order.status.should == 1
      @order.invoice_id.should == 7
      @order.freshbooks_client_id.should == 5
    end

    it 'is not created if there is not a freshbooks client' do
      FreshBooks.should_receive(:get_client_id).and_return(nil)
      FreshBooks.should_receive(:create_invoice).never

      @order.status.should == 1
      @order.create_freshbooks_invoice!
      @order.status.should == 0
    end

    it 'deals if the client disappears from freshbooks' do
      FreshBooks.should_receive(:get_client_id).exactly(2).times.and_return(2, nil)
      FreshBooks.should_receive(:create_invoice).once

      @order.status.should == 1
      @order.create_freshbooks_invoice!
      @order.status.should == 1

      order = FactoryGirl.create(:order, :partner => @order.partner)
      order.status.should == 1
      order.create_freshbooks_invoice!
      order.status.should == 0
    end
  end

  it 'increases the balance for a partner' do
    partner = FactoryGirl.create(:partner)
    partner.balance.should == 0
    partner.orders.count.should == 0
    FactoryGirl.create(:order, :partner => partner, :amount => 100)
    partner.reload
    partner.balance.should == 100
    partner.orders.count.should == 1
  end

end
