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

  context 'with geoip data' do
    before(:each) do
      @now = Time.now
      @web_request = WebRequest.new(:time => @now)
      @web_request.put_values('connect', {}, nil, {:city => "Sor\370", :primary_country => 'DK', :lat => 55.4387, :long => 11.5609})
    end

    it 'should set the country' do
      @web_request.country.should == 'DK'
    end

    it 'should set the city, converted to utf8' do
      @web_request.geoip_city.should == "Sorø"
    end

    it 'should set the latitude' do
      @web_request.geoip_latitude.should == 55.4387
    end

    it 'should set the longitude' do
      @web_request.geoip_longitude.should == 11.5609
    end

    it 'should be able to generate json' do
      json = JSON.generate(@web_request.attributes)
      JSON.parse(json).should == {
        "country" => ["DK"],
        "geoip_city" => ["Sorø"],
        "geoip_latitude" => ["55.4387"],
        "geoip_longitude" => ["11.5609"],
        "time" => ["#{@now.to_f}"],
        "path" => ["connect"]
      }
    end
  end

  context 'with partial geoip data' do
    before(:each) do
      @now = Time.now
      @web_request = WebRequest.new(:time => @now)
      @web_request.put_values('connect', {}, nil, {:primary_country => 'DK'})
    end

    it 'should set the country' do
      @web_request.country.should == 'DK'
    end

    it 'should not set the city' do
      @web_request.geoip_city.should == nil
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
      StatsCache.get_count(Stats.get_memcache_count_key('logins', @web_request.app_id, @web_request.time)).should == 1
    end

    context "without store_name set" do
      it "doesn't increment stats for store" do
        @web_request.save
        StatsCache.get_count(Stats.get_memcache_count_key('logins.google', @web_request.app_id, @web_request.time)).should == 0
      end
    end

    context "with store_name set" do
      it "increments stats for store" do
        @web_request.store_name = 'google'
        @web_request.save
        StatsCache.get_count(Stats.get_memcache_count_key('logins.google', @web_request.app_id, @web_request.time)).should == 1
      end
    end
  end
end
