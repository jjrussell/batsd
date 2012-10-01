require 'spec_helper'

describe StatsAggregation do
  before :each do
    @now = Time.now.beginning_of_day
    Timecop.freeze(@now + 30.minutes)
    @last_aggregation = @now - 1.day
    @stats = Stats.new
    Stats.stub(:new).and_return(@stats)
  end

  describe '#populate_hourly_stats' do
    context 'with generic offer' do
      before :each do
        @offer = FactoryGirl.create(:generic_offer).primary_offer
        Offer.stub(:find).and_return([@offer])
        @last_aggregation = @now - 1.day
        @offer.stub(:last_stats_aggregation_time).and_return(@last_aggregation)
        24.times.each do |i|
          key = Stats.get_memcache_count_key('paid_clicks', @offer.id, @last_aggregation + i.hour)
          Mc.increment_count(key, false, 1.day, 500 + i)
        end
      end

      it 'populates hourly stats' do
        StatsAggregation.new(['1234']).populate_hourly_stats
        24.times.each do |i|
          @stats.get_hourly_count('paid_clicks')[i].should == 500 + i
        end
      end
    end

    context 'with iOS app' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        Offer.stub(:find).and_return([@offer])
        @last_aggregation = @now - 1.day
        @offer.stub(:last_stats_aggregation_time).and_return(@last_aggregation)
        24.times.each do |i|
          key = Stats.get_memcache_count_key('logins', @offer.id, @last_aggregation + i.hour)
          Mc.increment_count(key, false, 1.day, 10000 + i)
        end
      end

      it 'populates hourly stats' do
        StatsAggregation.new(['1234']).populate_hourly_stats
        24.times.each do |i|
          @stats.get_hourly_count('logins')[i].should == 10000 + i
        end
      end
    end

    context 'with android app' do
      before :each do
        @app = FactoryGirl.create(:app, :platform => 'android')
        @offer = @app.primary_offer
        Offer.stub(:find).and_return([@offer])
        @last_aggregation = @now - 1.day
        @offer.stub(:last_stats_aggregation_time).and_return(@last_aggregation)
        24.times.each do |i|
          key = Stats.get_memcache_count_key('logins', @offer.id, @last_aggregation + i.hour)
          Mc.increment_count(key, false, 1.day, 10000 + i)
          key = Stats.get_memcache_count_key('logins.google', @offer.id, @last_aggregation + i.hour)
          Mc.increment_count(key, false, 1.day, 7000 + i)
          key = Stats.get_memcache_count_key('logins.gfan', @offer.id, @last_aggregation + i.hour)
          Mc.increment_count(key, false, 1.day, 3000 + i)
          key = Stats.get_memcache_count_key('logins.skt', @offer.id, @last_aggregation + i.hour)
          Mc.increment_count(key, false, 1.day, 1500 + i)
        end
      end

      it 'populates hourly stats' do
        StatsAggregation.new(['1234']).populate_hourly_stats
        24.times.each do |i|
          @stats.get_hourly_count('logins')[i].should == 10000 + i
        end
      end

      context 'that has a single distribution' do
        it "doesn't populate store-specific stats" do
          StatsAggregation.new(['1234']).populate_hourly_stats
          24.times.each do |i|
            @stats.get_hourly_count('logins.google')[i].should == 0
          end
        end
      end

      context 'that has a secondary GFan distribution' do
        it 'populates hourly store-specific stats for all distributions' do
          @app.add_app_metadata('android.GFan', 'xyz321')
          StatsAggregation.new(['1234']).populate_hourly_stats
          24.times.each do |i|
            @stats.get_hourly_count('logins.google')[i].should == 7000 + i
            @stats.get_hourly_count('logins.gfan')[i].should == 3000 + i
            @stats.get_hourly_count('logins.skt')[i].should == 0
          end
        end
      end

      context 'that has a secondary T-Store distribution' do
        it 'populates hourly store-specific stats for all distributions' do
          @app.add_app_metadata('android.SKTStore', 'xyz654')
          StatsAggregation.new(['1234']).populate_hourly_stats
          24.times.each do |i|
            @stats.get_hourly_count('logins.google')[i].should == 7000 + i
            @stats.get_hourly_count('logins.gfan')[i].should == 0
            @stats.get_hourly_count('logins.skt')[i].should == 1500 + i
          end
        end
      end
    end
  end

  after :each do
    Timecop.return
  end
end
