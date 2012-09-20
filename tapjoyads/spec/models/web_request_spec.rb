require 'spec_helper'

describe WebRequest do
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
