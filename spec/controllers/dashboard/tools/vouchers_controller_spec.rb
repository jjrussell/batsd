require 'spec_helper'

describe Dashboard::Tools::VouchersController do
  describe '#show' do
    before :each do
      @coupon = FactoryGirl.create(:coupon)
      @coupon.cache
      @voucher = FactoryGirl.create(:voucher, :coupon_id => @coupon.id)
      @voucher2 = FactoryGirl.create(:voucher, :coupon_id => @coupon.id)
      get(:show, :id => @coupon.id)
    end

    it 'should have an instance variable coupon' do
      assigns(:coupon).should == @coupon
    end
    it 'should have an instance variable vouchers' do
      assigns(:vouchers).should =~ [@voucher, @voucher2]
    end
    it 'should respond with 200' do
      should respond_with 200
    end
  end
end
