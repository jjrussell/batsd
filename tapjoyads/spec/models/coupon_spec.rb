require 'spec_helper'

describe Coupon do

  it { should have_many(:offers) }
  it { should belong_to(:partner) }
  it { should belong_to(:prerequisite_offer) }
  it { should have_one(:primary_offer) }

  describe '#coupon_discount_type' do
    it 'should return currency when discount_type is 0' do
      Coupon.coupon_discount_type(0).should == 'currency'
    end

    it 'should reutrn percentage otherwise' do
      Coupon.coupon_discount_type(1).should == 'percentage'
    end
  end

  describe '#create_new_coupon' do
    before :each do
      @coupon = FactoryGirl.create(:coupon)
      @partner_id = @coupon.partner.id
      Coupon.stub(:create!).and_return(@coupon)
      @params = { 'id' => '12345', 'title' => 'Amazon',
                  'description' => 'Buy stuff', 'fine_print' => 'bro',
                  'illustration_url' => 'http://illustration.com', 'start_date' => '2012-10-10',
                  'end_date' => '2012-10-12', 'discount' => { 'type' => '0', 'value' => '1000' },
                  'advertiser' => { 'name' => 'amazon', 'url' => 'amazon.com' },
                  'vouchers_expire' => { 'type' => 'type', 'date' => 'today' },
                  'partner_id' => '111'
                }
    end
    it 'should save a new coupon to the db' do
      Coupon.create_new_coupon(@params, @partner_id, @coupon.price, @coupon.instructions).should == @coupon
    end
  end

  describe '#hide!' do
    before :each do
      @coupon = FactoryGirl.create(:coupon, :hidden => false)
    end
    it 'should set coupon hidden to true' do
      @coupon.hide!
      @coupon.hidden.should be_true
    end
  end

  describe '#enabled?' do
    context 'enabled' do
      before :each do
        @coupon = FactoryGirl.create(:coupon)
        Offer.any_instance.stub(:enabled?).and_return(true)
      end
      it 'should return true' do
        @coupon.enabled?.should be_true
      end
    end
    context 'disabled' do
      before :each do
        @coupon = FactoryGirl.create(:coupon)
        Offer.any_instance.stub(:enabled?).and_return(false)
      end
      it 'should return true' do
        @coupon.enabled?.should be_false
      end
    end
  end

end
