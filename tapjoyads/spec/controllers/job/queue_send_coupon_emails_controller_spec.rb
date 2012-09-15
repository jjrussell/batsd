require 'spec_helper'

describe Job::QueueSendCouponEmailsController do
  before :each do
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)
    @coupon = FactoryGirl.create(:coupon)
    Coupon.stub(:find_in_cache).and_return(@coupon)
    @message = { :coupon_id => @coupon.id,
                 :email_address => 'test@test.com',
                 :click_key => '123' }.to_json
    @voucher = FactoryGirl.create(:voucher)
    Voucher.stub(:request_voucher).and_return(@voucher)
  end

  it 'should cache the currency object' do
    TapjoyMailer.any_instance.should_receive(:email_coupon_offer)
    get(:run_job, :message => @message)
  end
end
