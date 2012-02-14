require 'spec_helper'

describe Conversion do
  subject { Factory(:conversion) }

  describe '.belongs_to' do
    it { should belong_to(:publisher_app) }
    it { should belong_to(:advertiser_offer) }
    it { should belong_to(:publisher_partner) }
    it { should belong_to(:advertiser_partner) }
  end

  describe '#valid?' do
    it { should validate_numericality_of(:advertiser_amount) }
    it { should validate_numericality_of(:publisher_amount) }
    it { should validate_numericality_of(:tapjoy_amount) }
  end

  before :each do
    @conversion = Factory.build(:conversion)
  end

  it "provides a mechanism to set reward_type from a string" do
    @conversion.reward_type.should == 1
    Conversion::REWARD_TYPES.each do |k, v|
      @conversion.reward_type_string = k
      @conversion.reward_type.should == v
    end
  end

  context "when saved" do
    it "updates the publisher's pending earnings" do
      pub_partner = @conversion.publisher_partner
      pub_partner.pending_earnings.should == 0
      @conversion.save!
      pub_partner.reload
      pub_partner.pending_earnings.should == 70
    end

    it "updates the advertiser's balance" do
      adv_partner = @conversion.advertiser_partner
      adv_partner.balance.should == 0
      @conversion.save!
      adv_partner.reload
      adv_partner.balance.should == -100
    end
  end
end
