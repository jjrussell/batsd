require 'spec_helper'

describe WebRequest do
  context 'attributes' do
    before(:each) do
      @web_request = WebRequest.new
    end

    it 'should have offer_is_paid' do
      @web_request.offer_is_paid = 'true'
      @web_request.offer_is_paid.should be_true
    end

    it 'should have offer_daily_budget' do
      @web_request.offer_daily_budget = '5'
      @web_request.offer_daily_budget.should == 5
    end

    it 'should have offer_overall_budget' do
      @web_request.offer_overall_budget = '1337'
      @web_request.offer_overall_budget.should == 1337
    end

    it 'should have advertiser_balance' do
      @web_request.advertiser_balance = '10'
      @web_request.advertiser_balance.should == 10
    end
  end

  context "when saved" do
    before :each do
      @web_request = WebRequest.new(:time => Time.now)
      @web_request.path   = "connect"
      @web_request.app_id = "abc123"
    end

    it 'increments stats for logins' do
      @web_request.save
      Mc.get_count(Stats.get_memcache_count_key('logins', @web_request.app_id, @web_request.time)).should == 1
    end

    context "without store_name set" do
      it "doesn't increment stats for store" do
        @web_request.save
        Mc.get_count(Stats.get_memcache_count_key('logins.google', @web_request.app_id, @web_request.time)).should == 0
      end
    end

    context "with store_name set" do
      it "increments stats for store" do
        @web_request.store_name = 'google'
        @web_request.save
        Mc.get_count(Stats.get_memcache_count_key('logins.google', @web_request.app_id, @web_request.time)).should == 1
      end
    end
  end
end
