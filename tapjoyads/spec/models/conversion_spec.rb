require 'spec_helper'

# TODO: test REWARD_TYPES

describe Conversion do
  subject { FactoryGirl.create(:conversion) }

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

  describe '#update_realtime_stats' do
    it "increments stats for offer" do
      subject.update_realtime_stats
      StatsCache.get_count(Stats.get_memcache_count_key('paid_installs', subject.advertiser_offer_id, subject.created_at)).should == 1
      StatsCache.get_count(Stats.get_memcache_count_key('installs_spend', subject.advertiser_offer_id, subject.created_at)).should == -100
    end

    it "increments stats for app" do
      subject.update_realtime_stats
      StatsCache.get_count(Stats.get_memcache_count_key('published_installs', subject.publisher_app_id, subject.created_at)).should == 1
      StatsCache.get_count(Stats.get_memcache_count_key('installs_revenue', subject.publisher_app_id, subject.created_at)).should == 70
    end

    context "when store_name is not set" do
      it "doesn't increments stats for store" do
        subject.update_realtime_stats
        StatsCache.get_count(Stats.get_memcache_count_key('installs_revenue', subject.publisher_app_id, subject.created_at)).should == 70
        StatsCache.get_count(Stats.get_memcache_count_key('installs_revenue.google', subject.publisher_app_id, subject.created_at)).should == 0
      end
    end

    context "when store_name is set" do
      it 'increments stats for app generally and for the specific store' do
        subject.store_name = 'google'
        subject.update_realtime_stats
        StatsCache.get_count(Stats.get_memcache_count_key('installs_revenue', subject.publisher_app_id, subject.created_at)).should == 70
        StatsCache.get_count(Stats.get_memcache_count_key('installs_revenue.google', subject.publisher_app_id, subject.created_at)).should == 70
      end
    end
  end
end
