require 'spec_helper'

describe StatsAggregation do
  before :each do
    @now = Time.zone.now.beginning_of_day
    Timecop.freeze(@now + 30.minutes)
    @last_aggregation = @now - 1.day
  end

  describe '#populate_hourly_stats' do
    before :each do
      @stats = Stats.new
      Stats.stub(:new).and_return(@stats)
    end

    context 'with generic offer' do
      before :each do
        @offer = FactoryGirl.create(:generic_offer).primary_offer
        Offer.stub(:find).and_return([@offer])
        @offer.stub(:last_stats_aggregation_time).and_return(@last_aggregation)
        24.times.each do |i|
          key = Stats.get_memcache_count_key('paid_clicks', @offer.id, @last_aggregation + i.hour)
          StatsCache.increment_count(key, false, 1.day, 500 + i)
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
        @offer.stub(:last_stats_aggregation_time).and_return(@last_aggregation)
        24.times.each do |i|
          key = Stats.get_memcache_count_key('logins', @offer.id, @last_aggregation + i.hour)
          StatsCache.increment_count(key, false, 1.day, 10000 + i)
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
        @offer.stub(:last_stats_aggregation_time).and_return(@last_aggregation)
        24.times.each do |i|
          key = Stats.get_memcache_count_key('logins', @offer.id, @last_aggregation + i.hour)
          StatsCache.increment_count(key, false, 1.day, 10000 + i)
          key = Stats.get_memcache_count_key('logins.google', @offer.id, @last_aggregation + i.hour)
          StatsCache.increment_count(key, false, 1.day, 7000 + i)
          key = Stats.get_memcache_count_key('logins.gfan', @offer.id, @last_aggregation + i.hour)
          StatsCache.increment_count(key, false, 1.day, 3000 + i)
          key = Stats.get_memcache_count_key('logins.skt', @offer.id, @last_aggregation + i.hour)
          StatsCache.increment_count(key, false, 1.day, 1500 + i)
        end
      end

      it 'populates hourly stats' do
        StatsAggregation.new(['1234']).populate_hourly_stats
        24.times.each do |i|
          @stats.get_hourly_count('logins')[i].should == 10000 + i
        end
      end

      context 'that has a single distribution' do
        it 'populates hourly store-specific stats for all distributions' do
          StatsAggregation.new(['1234']).populate_hourly_stats
          24.times.each do |i|
            @stats.get_hourly_count('logins.google')[i].should == 7000 + i
            @stats.get_hourly_count('logins.gfan')[i].should == 0
            @stats.get_hourly_count('logins.skt')[i].should == 0
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

  describe '#verify_hourly_and_populate_daily_stats' do
    before :each do
      StatsAggregation.any_instance.stub(:verify_web_request_stats_over_range)
      StatsAggregation.any_instance.stub(:verify_conversion_stats_over_range)
    end

    context 'with generic offer' do
      before :each do
        @offer = FactoryGirl.create(:generic_offer).primary_offer
        Offer.stub(:find).and_return([@offer])
        @offer.stub(:last_stats_aggregation_time).and_return(@last_aggregation)
        @offer.stub(:last_daily_stats_aggregation_time).and_return(@last_aggregation)
        @daily_count = 0
        24.times.each do |i|
          key = Stats.get_memcache_count_key('paid_clicks', @offer.id, @last_aggregation + i.hour)
          count = 500 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @daily_count += count
        end
        StatsAggregation.new([@offer.id]).populate_hourly_stats
      end

      it 'populates daily stats' do
        StatsAggregation.new([@offer.id]).verify_hourly_and_populate_daily_stats
        daily_stat_row = Stats.new(:key => "app.#{@last_aggregation.strftime('%Y-%m')}.#{@offer.id}", :load_from_memcache => false)
        daily_stat_row.get_daily_count('paid_clicks')[@last_aggregation.day - 1].should == @daily_count
      end

      it 'sets last daily stats aggregation time' do
        StatsAggregation.new([@offer.id]).verify_hourly_and_populate_daily_stats
        @offer.last_daily_stats_aggregation_time = @last_aggregation + 1.day
      end
    end

    context 'with iOS app' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        Offer.stub(:find).and_return([@offer])
        @offer.stub(:last_stats_aggregation_time).and_return(@last_aggregation)
        @offer.stub(:last_daily_stats_aggregation_time).and_return(@last_aggregation)
        @daily_count = 0
        24.times.each do |i|
          key = Stats.get_memcache_count_key('logins', @offer.id, @last_aggregation + i.hour)
          count = 10000 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @daily_count += count
        end
        StatsAggregation.new([@offer.id]).populate_hourly_stats
      end

      it 'populates daily stats' do
        StatsAggregation.new([@offer.id]).verify_hourly_and_populate_daily_stats
        daily_stat_row = Stats.new(:key => "app.#{@last_aggregation.strftime('%Y-%m')}.#{@offer.id}", :load_from_memcache => false)
        daily_stat_row.get_daily_count('logins')[@last_aggregation.day - 1].should == @daily_count
      end
    end

    context 'with android app' do
      before :each do
        @app = FactoryGirl.create(:app, :platform => 'android')
        @app.add_app_metadata('android.GFan', 'xyz321')
        @app.add_app_metadata('android.SKTStore', 'xyz654')
        @offer = @app.primary_offer
        Offer.stub(:find).and_return([@offer])
        @offer.stub(:last_stats_aggregation_time).and_return(@last_aggregation)
        @offer.stub(:last_daily_stats_aggregation_time).and_return(@last_aggregation)
        @daily_count = {}
        %w( all google gfan skt ).each {|type| @daily_count[type] = 0}
        24.times.each do |i|
          key = Stats.get_memcache_count_key('logins', @offer.id, @last_aggregation + i.hour)
          count = 10000 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @daily_count['all'] += count
          key = Stats.get_memcache_count_key('logins.google', @offer.id, @last_aggregation + i.hour)
          count = 7000 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @daily_count['google'] += count
          key = Stats.get_memcache_count_key('logins.gfan', @offer.id, @last_aggregation + i.hour)
          count = 3000 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @daily_count['gfan'] += count
          key = Stats.get_memcache_count_key('logins.skt', @offer.id, @last_aggregation + i.hour)
          count = 1500 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @daily_count['skt'] += count
        end
        StatsAggregation.new([@offer.id]).populate_hourly_stats
      end

      it 'populates daily stats' do
        StatsAggregation.new([@offer.id]).verify_hourly_and_populate_daily_stats
        daily_stat_row = Stats.new(:key => "app.#{@last_aggregation.strftime('%Y-%m')}.#{@offer.id}", :load_from_memcache => false)
        daily_stat_row.get_daily_count('logins')[@last_aggregation.day - 1].should == @daily_count['all']
        daily_stat_row.get_daily_count('logins.google')[@last_aggregation.day - 1].should == @daily_count['google']
        daily_stat_row.get_daily_count('logins.gfan')[@last_aggregation.day - 1].should == @daily_count['gfan']
        daily_stat_row.get_daily_count('logins.skt')[@last_aggregation.day - 1].should == @daily_count['skt']
      end
    end
  end

  describe '.aggregate_hourly_group_stats' do
    before :each do
      $stdout = File.new( '/tmp/output', 'w' )
    end

    context 'with generic offer' do
      before :each do
        @partner_daily_count = 0
        @total_daily_count = 0
        @partner = FactoryGirl.create(:partner)
        @partner.save
        @offer1 = FactoryGirl.create(:generic_offer, :partner => @partner).primary_offer
        @offer1.last_stats_aggregation_time = @last_aggregation
        @offer1.save
        24.times.each do |i|
          key = Stats.get_memcache_count_key('paid_clicks', @offer1.id, @last_aggregation + i.hour)
          count = 500 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @partner_daily_count += count
          @total_daily_count += count
        end
        @offer2 = FactoryGirl.create(:generic_offer, :partner => @partner).primary_offer
        @offer2.last_stats_aggregation_time = @last_aggregation
        @offer2.save
        24.times.each do |i|
          key = Stats.get_memcache_count_key('paid_clicks', @offer2.id, @last_aggregation + i.hour)
          count = 1500 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @partner_daily_count += count
          @total_daily_count += count
        end
        @offer3 = FactoryGirl.create(:generic_offer).primary_offer
        @offer3.last_stats_aggregation_time = @last_aggregation
        @offer3.save
        24.times.each do |i|
          key = Stats.get_memcache_count_key('paid_clicks', @offer3.id, @last_aggregation + i.hour)
          count = 5000 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @total_daily_count += count
        end
        StatsAggregation.new([@offer1.id, @offer2.id, @offer3.id]).populate_hourly_stats
      end

      it 'populates partner hourly stats' do
        StatsAggregation.aggregate_hourly_group_stats(@last_aggregation)
        partner_stat_row = Stats.new(:key => "partner.#{@last_aggregation.strftime('%Y-%m-%d')}.#{@offer1.partner.id}", :load_from_memcache => false)
        24.times.each do |i|
          partner_stat_row.get_hourly_count('paid_clicks')[i].should == 2000 + i * 2
        end
      end

      it 'populates global hourly stats' do
        StatsAggregation.aggregate_hourly_group_stats(@last_aggregation)
        global_stat_row = Stats.new(:key => "global.#{@last_aggregation.strftime('%Y-%m-%d')}", :load_from_memcache => false)
        24.times.each do |i|
          global_stat_row.get_hourly_count('paid_clicks')[i].should == 7000 + i * 3
        end
      end

      context 'when aggregating daily stats' do
        it 'populates partner daily stats' do
          StatsAggregation.aggregate_hourly_group_stats(@last_aggregation, true)
          partner_stat_row = Stats.new(:key => "partner.#{@last_aggregation.strftime('%Y-%m')}.#{@offer1.partner.id}", :load_from_memcache => false)
          partner_stat_row.get_daily_count('paid_clicks')[@last_aggregation.day - 1].should == @partner_daily_count
        end

        it 'populates global daily stats' do
          StatsAggregation.aggregate_hourly_group_stats(@last_aggregation, true)
          global_stat_row = Stats.new(:key => "global.#{@last_aggregation.strftime('%Y-%m')}", :load_from_memcache => false)
          global_stat_row.get_daily_count('paid_clicks')[@last_aggregation.day - 1].should == @total_daily_count
        end
      end
    end

    context 'with android app' do
      before :each do
        @partner_daily_count = 0
        @total_daily_count = 0
        @partner = FactoryGirl.create(:partner)
        @partner.save
        @app1 = FactoryGirl.create(:app, :platform => 'android', :partner => @partner)
        @app1.add_app_metadata('android.SKTStore', 'xyz654')
        @app1.save
        @offer1 = @app1.primary_offer
        @offer1.last_stats_aggregation_time = @last_aggregation
        @offer1.save
        24.times.each do |i|
          key = Stats.get_memcache_count_key('logins', @offer1.id, @last_aggregation + i.hour)
          StatsCache.increment_count(key, false, 1.day, 8000 + i * 2)
          key = Stats.get_memcache_count_key('logins.google', @offer1.id, @last_aggregation + i.hour)
          count = 7000 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @total_daily_count += count
          key = Stats.get_memcache_count_key('logins.skt', @offer1.id, @last_aggregation + i.hour)
          count = 1000 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @partner_daily_count += count
        end
        @app2 = FactoryGirl.create(:non_live_app, :platform => 'android', :partner => @partner)
        @app2.add_app_metadata('android.SKTStore', 'tuv987', true)
        @app2.save
        @offer2 = @app2.primary_offer
        @offer2.last_stats_aggregation_time = @last_aggregation
        @offer2.save
        24.times.each do |i|
          key = Stats.get_memcache_count_key('logins', @offer2.id, @last_aggregation + i.hour)
          StatsCache.increment_count(key, false, 1.day, 2500 + i)
          key = Stats.get_memcache_count_key('logins.skt', @offer2.id, @last_aggregation + i.hour)
          count = 2500 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @partner_daily_count += count
        end
        @app3 = FactoryGirl.create(:app, :platform => 'android')
        @app3.add_app_metadata('android.GFan', 'xyz321')
        @app3.add_app_metadata('android.SKTStore', 'abc456')
        @app3.save
        @offer3 = @app3.primary_offer
        @offer3.last_stats_aggregation_time = @last_aggregation
        @offer3.save
        24.times.each do |i|
          key = Stats.get_memcache_count_key('logins', @offer3.id, @last_aggregation + i.hour)
          StatsCache.increment_count(key, false, 1.day, 10000 + i * 3)
          key = Stats.get_memcache_count_key('logins.google', @offer3.id, @last_aggregation + i.hour)
          count = 6000 + i
          StatsCache.increment_count(key, false, 1.day, count)
          @total_daily_count += count
          key = Stats.get_memcache_count_key('logins.gfan', @offer3.id, @last_aggregation + i.hour)
          StatsCache.increment_count(key, false, 1.day, 3000 + i)
          key = Stats.get_memcache_count_key('logins.skt', @offer3.id, @last_aggregation + i.hour)
          StatsCache.increment_count(key, false, 1.day, 1000 + i)
        end
        StatsAggregation.new([@offer1.id, @offer2.id, @offer3.id]).populate_hourly_stats
      end

      it 'populates partner hourly stats' do
        StatsAggregation.aggregate_hourly_group_stats(@last_aggregation)
        partner_stat_row = Stats.new(:key => "partner.#{@last_aggregation.strftime('%Y-%m-%d')}.#{@offer1.partner.id}", :load_from_memcache => false)
        24.times.each do |i|
          partner_stat_row.get_hourly_count('logins')[i].should == 10500 + i * 3
          partner_stat_row.get_hourly_count('logins.google')[i].should == 7000 + i
          partner_stat_row.get_hourly_count('logins.skt')[i].should == 3500 + i * 2
        end
      end

      it 'populates global hourly stats' do
        StatsAggregation.aggregate_hourly_group_stats(@last_aggregation)
        global_stat_row = Stats.new(:key => "global.#{@last_aggregation.strftime('%Y-%m-%d')}", :load_from_memcache => false)
        24.times.each do |i|
          global_stat_row.get_hourly_count('logins')[i].should == 20500 + i * 6
          global_stat_row.get_hourly_count('logins.google')[i].should == 13000 + i * 2
          global_stat_row.get_hourly_count('logins.skt')[i].should == 4500 + i * 3
          global_stat_row.get_hourly_count('logins.gfan')[i].should == 3000 + i
        end
      end

      context 'when aggregating daily stats' do
        it 'populates partner daily stats' do
          StatsAggregation.aggregate_hourly_group_stats(@last_aggregation, true)
          partner_stat_row = Stats.new(:key => "partner.#{@last_aggregation.strftime('%Y-%m')}.#{@offer1.partner.id}", :load_from_memcache => false)
          partner_stat_row.get_daily_count('logins.skt')[@last_aggregation.day - 1].should == @partner_daily_count
        end

        it 'populates global daily stats' do
          StatsAggregation.aggregate_hourly_group_stats(@last_aggregation, true)
          global_stat_row = Stats.new(:key => "global.#{@last_aggregation.strftime('%Y-%m')}", :load_from_memcache => false)
          global_stat_row.get_daily_count('logins.google')[@last_aggregation.day - 1].should == @total_daily_count
        end
      end
    end

    after :each do
      $stdout = STDOUT
    end
  end

  after :each do
    Timecop.return
  end
end
