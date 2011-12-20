require 'spec/spec_helper'

describe BillingController do
  before :each do
    activate_authlogic
    @pending_earnings = 1000
    user = Factory(:user)
    partner = Factory(:partner, :users => [ user ], :pending_earnings => @pending_earnings)
    login_as(user)
  end

  describe 'trasnfer freeze' do
    describe 'during freeze' do
      before :each do
        Time.stubs(:now).returns(Time.parse('2011-12-22'))
      end

      it 'should not show xfer page' do
        get :transfer_funds
        @response.should render_template('billing/no_transfer.html.haml')
      end

      it 'should not create xfer' do
        post :create_transfer, :transfer_amount => 1
        flash[:error].should =~ /error/
      end
    end

    describe 'after freeze' do
      before :each do
        Time.stubs(:now).returns(Time.parse('2011-12-23'))
      end

      it 'should show xfer page' do
        get :transfer_funds
        @response.should render_template('billing/transfer_funds.html.haml')
      end

      it 'should resume creating xfer' do
        post :create_transfer, :transfer_amount => 1
        flash[:error].should be_nil
      end
    end
  end
end
