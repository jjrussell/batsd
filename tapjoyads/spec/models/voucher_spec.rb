require 'spec_helper'

describe Voucher do
  subject { FactoryGirl.create(:voucher) }

  it { should belong_to(:coupon) }

  describe '#request_voucher' do
    before :each do
      @coupon = FactoryGirl.create(:coupon)
    end
  end

  describe '#create_new_voucher' do
    before :each do
      @id = FactoryGirl.create(:coupon).id
      @params = { 'id' => '123456', 'redemption_code' => 'code', 'acquired_at' => '2012-10-10',
                   'expires_at' => '2012-10-10', 'barcode_url' => 'http://barcode.com' }
      @voucher = FactoryGirl.create(:voucher)
      Voucher.stub(:create!).and_return(@voucher)
    end
    it 'should save a new voucher to the db' do
      Voucher.create_new_voucher(@params, @id, @voucher.email_address, @voucher.click_key).should == @voucher
    end
  end
end
