require 'test_helper'

class PartnersControllerTest < ActionController::TestCase
  setup :activate_authlogic
  context "when creating create transfer" do
    setup do
      @user = Factory(:admin)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      Factory(:app, :partner => @partner)
      Factory(:app, :partner => @partner)
      login_as(@user)
    end

    should "log transfer and math should work out" do
      amount = rand(100) + 100

      get :create_transfer, { :transfer_amount => amount, :id => @partner.id }
      @partner.reload

      assert_response :redirect
      assert_equal 1, @partner.orders.length
      assert_equal 1, @partner.payouts.length
      assert_equal 10000 - amount*100, @partner.pending_earnings
      assert_equal 10000 + amount*100, @partner.balance
    end

    should "create bonus if necessary" do
      @partner.transfer_bonus = 0.1
      @partner.save
      amount = rand(100) + 100
      bonus = (amount * @partner.transfer_bonus)

      get :create_transfer, { :transfer_amount => amount, :id => @partner.id }
      @partner.reload

      assert_equal 2, @partner.orders.length
      assert_equal 1, @partner.payouts.length
      assert_equal 10000 - amount*100, @partner.pending_earnings
      assert_equal 10000 + amount*100 + bonus*100, @partner.balance
    end

  end
  
  context "when creating marketing credits" do
    setup do 
      @user = Factory(:admin)
      @partner = Factory(:partner, :users => [@user])
      Factory(:app, :partner => @partner)
      Factory(:app, :partner => @partner)
      login_as(@user)
    end
    
    should "log marketing credits" do
      amount = rand(100) + 100
      
      post :create_marketing_credits, {:id => @partner.id, :order => { :amount => amount.to_s, :partner_id => @partner.id, :payment_method => 4, :note => 'Test' } }
      assert_response :redirect
      assert_match /The Marketing Credits order of .* was successfully created./, flash[:notice]
      @partner.reload
      
      order = @partner.orders[0]
      assert order.is_marketing_credits?
      assert_equal amount*100, order.amount
      assert_equal 'Test', order.note
    end
    
    should "not allow other payment methods" do
       amount = rand(100) + 100

       post :create_marketing_credits, {:id => @partner.id, :order => { :amount => amount.to_s, :partner_id => @partner.id, :payment_method => 2, :note => 'Test' } }
       assert_response :redirect
       assert_equal "The Marketing Credits order was unable to be processed.", flash[:error]
       @partner.reload

       order = @partner.orders[0]
       assert_nil order
     end
  end
end
