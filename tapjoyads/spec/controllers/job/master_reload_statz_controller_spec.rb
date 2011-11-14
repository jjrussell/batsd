require 'spec/spec_helper'

describe Job::MasterReloadStatzController do
  before :each do
    Time.zone.stubs(:now).returns(Time.zone.parse('2011-02-15'))
    @start_time = Time.zone.now - 1.day
    @end_time = Time.zone.now
    @controller.expects(:authenticate).at_least_once.returns(true)

    conditions = [
      "path LIKE '%reward%'",
      "time >= '#{@start_time.to_s(:db)}'",
      "time < '#{@end_time.to_s(:db)}'",
    ]
    VerticaCluster.
      expects(:query).
      once.
      with('analytics.actions', :select => 'max(time)').
      returns([{ :max => Time.zone.parse('2011-02-15') }])

    vertica_options = {
        :select     => 'offer_id, count(*) AS conversions',
        :group      => 'offer_id',
        :conditions => conditions.join(' AND '),
    }
    VerticaCluster.
      expects(:query).
      once.
      with('analytics.actions', vertica_options).
      returns([{ :stuff => 'stuff' }])

    vertica_options = {
        :select     => 'publisher_app_id AS offer_id, count(*) AS published_offers, sum(publisher_amount) AS offers_revenue',
        :group      => 'publisher_app_id',
        :conditions => conditions.join(' AND '),
    }
    VerticaCluster.
      expects(:query).
      once.
      with('analytics.actions', vertica_options).
      returns([{ :offers_revenue => 5 }])
  end

  describe 'when caching stats' do
    it 'should save memcache values' do
      get :index

      stats_hash = {
        "conversions"=>nil,
        "offers_revenue"=>"$0.05",
        "published_offers"=>nil
      }
      stats_array = [[nil, stats_hash]]

      Mc.get("statz.top_metadata.24_hours").should == {}
      Mc.get("statz.top_stats.24_hours").should == stats_array
      Mc.get("statz.metadata.24_hours").should == {}
      Mc.get("statz.stats.24_hours").should == stats_array
      Mc.get('statz.last_updated_start.24_hours').should == @start_time.to_f
      Mc.get('statz.last_updated_end.24_hours').should == @end_time.to_f
    end
  end
end
