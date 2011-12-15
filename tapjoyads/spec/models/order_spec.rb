require 'spec_helper'

describe Order do
  before :each do
    @order = Factory(:order)
  end

  it { should belong_to :partner }

  it { should validate_presence_of :partner }
  it { should validate_numericality_of :amount }

  describe "an invoice" do
    it "should be created if the client exists in freshbooks" do
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

    it "should not be created if there isn't a freshbooks client" do
      FreshBooks.expects(:get_client_id).returns(nil)
      FreshBooks.expects(:create_invoice).never

      @order.status.should == 1
      @order.create_freshbooks_invoice!
      @order.status.should == 0
    end

    it "should deal if the client disappears from freshbooks" do
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

end
