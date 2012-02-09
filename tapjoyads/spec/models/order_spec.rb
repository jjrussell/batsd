require 'spec_helper'

describe Order do

  before :each do
    @order = Factory(:order)
  end

  describe '.belongs_to' do
    it { should belong_to :partner }
  end

  describe '#valid?' do
    it { should validate_presence_of :partner }
    it { should validate_numericality_of :amount }
    it { should ensure_inclusion_of(:status).in_range(Order::STATUS_CODES.keys) }
    it { should ensure_inclusion_of(:payment_method).in_range(Order::PAYMENT_METHODS.keys) }
  end

  describe 'an invoice' do
    it 'should be created if the client exists in freshbooks' do
      FreshBooks.expects(:get_client_id).returns(5)
      FreshBooks.expects(:create_invoice).returns(7)

      @order.status.should == 1
      @order.invoice_id.should == nil
      @order.freshbooks_client_id.should == nil

      @order.create_freshbooks_invoice!

      @order.status.should == 1
      @order.invoice_id.should == 7
      @order.freshbooks_client_id.should == 5
    end

    it 'should not be created if there is not a freshbooks client' do
      FreshBooks.expects(:get_client_id).returns(nil)
      FreshBooks.expects(:create_invoice).never

      @order.status.should == 1
      @order.create_freshbooks_invoice!
      @order.status.should == 0
    end

    it 'should deal if the client disappears from freshbooks' do
      FreshBooks.expects(:get_client_id).times(2).returns(2, nil)
      FreshBooks.expects(:create_invoice).once

      @order.status.should == 1
      @order.create_freshbooks_invoice!
      @order.status.should == 1

      order = Factory(:order, :partner => @order.partner)
      order.status.should == 1
      order.create_freshbooks_invoice!
      order.status.should == 0
    end
  end

  context 'An Order' do
    before :each do
      @partner = Factory(:partner)
    end

    it 'increases the balance for a partner' do
      @partner.balance.should == 0
      @partner.orders.count.should == 0
      Factory(:order, :partner => @partner, :amount => 100)
      @partner.reload
      @partner.balance.should == 100
      @partner.orders.count.should == 1
    end
  end

end
