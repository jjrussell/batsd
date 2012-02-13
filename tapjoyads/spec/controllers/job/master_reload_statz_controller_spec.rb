require 'spec/spec_helper'

describe Job::MasterReloadStatzController do
  before :each do
    Time.zone.stubs(:now).returns(Time.zone.parse('2011-02-15'))
    @start_time = Time.zone.now - 1.day
    @end_time = Time.zone.now
    @controller.expects(:authenticate).at_least_once.returns(true)
  end

  describe 'when caching stats' do
    it 'should save memcache values' do
      100.times { Factory(:email_offer) }
      stub_vertica
      get :index

      expected_hash = {
        :android=>{:adv_amount=>"$0.00", :count=>"0", :pub_amount=>"$0.00"},
        :iphone=>{:adv_amount=>"$0.00", :count=>"0", :pub_amount=>"$0.00"},
        :total=>{:adv_amount=>"$0.01", :count=>"1", :pub_amount=>"$0.01"},
        :tj_games=>{:adv_amount=>"$0.01", :count=>"1", :pub_amount=>"$0.01"},
      }
      Mc.get("statz.money.24_hours").should == expected_hash

      top_metadata = Mc.get("statz.top_metadata.24_hours")
      top_metadata.length.should == 100
      top_metadata.keys.should_not include @worst_offer.id

      top_stats = Mc.get("statz.top_stats.24_hours")
      top_keys = top_stats.map { |item| item.first }
      top_keys.length.should == 100
      top_keys.should_not include @worst_offer.id

      metadata = Mc.get("statz.metadata.24_hours")
      metadata.length.should == 101
      metadata.keys.should include @worst_offer.id

      item = metadata.first
      offer = Offer.find(item.first)
      metadata_hash = item.last
      metadata_hash.should == {
        'icon_url'           => offer.get_icon_url,
        'offer_name'         => offer.name_with_suffix,
        'price'              => currency(offer.price),
        'payment'            => currency(offer.payment),
        'balance'            => currency(offer.partner.balance),
        'conversion_rate'    => percentage(offer.conversion_rate),
        'platform'           => offer.get_platform,
        'featured'           => offer.featured?,
        'rewarded'           => offer.rewarded?,
        'offer_type'         => offer.item_type,
        'overall_store_rank' => '-',
        'sales_rep'          => offer.partner.sales_rep.to_s
      }

      stats = Mc.get("statz.stats.24_hours")
      cached_stats_keys = stats.map { |item| item.first }
      cached_stats_keys.length.should == 101
      cached_stats_keys.should include @worst_offer.id

      Mc.get('statz.last_updated_start.24_hours').should == @start_time.to_f
      Mc.get('statz.last_updated_end.24_hours').should == @end_time.to_f

      response.body.should == 'ok'
    end

    it 'should generate weekly and monthly timeframes' do
      start_time = Time.zone.now - 7.days
      end_time = Time.zone.now

      stub_vertica(start_time, end_time)

      start_time = Time.zone.now - 30.days
      end_time = Time.zone.now

      stub_vertica(start_time, end_time)

      get :daily

      response.body.should == 'ok'
    end

    it 'should generate combined ranks' do
      apps = [
        Factory(:app,
          :platform => 'iphone'),
        Factory(:app,
          :platform => 'iphone'),
        Factory(:app,
          :platform => 'android'),
        Factory(:app,
          :platform => 'android'),
      ]
      
      app_metadatas = [
        Factory(:app_metadata,
          :store_id => 'ios.free',
          :price => 0),
        Factory(:app_metadata,
          :store_id => 'ios.paid',
          :price => 1),
        Factory(:app_metadata,
          :store_id => 'android.free',
          :store_name => 'Market',
          :price => 0),
        Factory(:app_metadata,
          :store_id => 'android.paid',
          :store_name => 'Market',
          :price => 1),
      ]

      apps.each_index do |i| 
        apps[i].add_app_metadata(app_metadatas[i])
        apps[i].reload.save!
      end

      stub_vertica

      hash = {'ios.free' => [1]}
      Mc.put('store_ranks.ios.overall.free.united_states', hash)
      hash = {'ios.paid' => [1]}
      Mc.put('store_ranks.ios.overall.paid.united_states', hash)
      hash = {'android.free' => [1]}
      Mc.put('store_ranks.android.overall.free.english', hash)
      hash = {'android.paid' => [1]}
      Mc.put('store_ranks.android.overall.paid.english', hash)

      get :index

      metadata = Mc.get("statz.metadata.24_hours")
      apps.each do |app|
        metadata[app.id]['overall_store_rank'].should == [1]
      end
    end
  end
end

def money_options(start_time, end_time)
  {
    :select =>
      'source, ' +
      'app_platform, ' +
      'count(path), ' +
      '-sum(advertiser_amount) as adv_amount, ' +
      'sum(publisher_amount) as pub_amount',
    :join =>
      'analytics.apps_partners on ' +
      'actions.publisher_app_id = apps_partners.app_id',
    :conditions =>
      "path = '[reward]' and " +
      "app_platform != 'windows' and " +
      "time >= '#{start_time.to_s(:db)}' AND " +
      "time < '#{end_time.to_s(:db)}'",
    :group => 'source, app_platform',
  }
end

def advertiser_options(start_time, end_time)
  {
    :select     =>
      'offer_id, ' +
      'count(path) AS conversions, ' +
      '-sum(advertiser_amount) AS spend',
    :group      => 'offer_id',
    :conditions => query_conditions(start_time, end_time).join(' AND '),
  }
end

def publisher_options(start_time, end_time)
  {
    :select     =>
      'publisher_app_id AS offer_id, ' +
      'count(path) AS published_offers, ' +
      'sum(publisher_amount + tapjoy_amount) AS gross_revenue, ' +
      'sum(publisher_amount) AS publisher_revenue',
    :group      => 'publisher_app_id',
    :conditions => query_conditions(start_time, end_time).join(' AND '),
  }
end

def stub_vertica(start_time = nil, end_time = nil)
  start_time ||= @start_time
  end_time ||= @end_time
  stats_to_be_cached = []
  Offer.all.each_with_index do |offer, index|
    stats_to_be_cached << {
      'offer_id' => offer.id,
      'spend' => 100 - index,
      'gross_revenue' => 100 + index,
      'publisher_revenue' => 50 + index,
    }
  end

  @worst_offer = Factory(:app).primary_offer
  stats_to_be_cached << {
    'offer_id' => @worst_offer.id,
    'spend' => 0,
    'gross_revenue' => 0,
    'publisher_revenue' => 0,
  }

  adv_stats = stats_to_be_cached.map do |item|
    {
      :offer_id => item['offer_id'],
      :spend => item['spend'],
    }
  end

  pub_stats = stats_to_be_cached.map do |item|
    {
      :offer_id => item['offer_id'],
      :gross_revenue => item['gross_revenue'],
      :publisher_revenue => item['publisher_revenue'],
    }
  end

  VerticaCluster.
    expects(:query).
    once.
    with('analytics.actions', :select => 'max(time)').
    returns([{ :max => Time.zone.parse('2011-02-15') }])

  VerticaCluster.
    expects(:query).
    once.
    with('analytics.actions', money_options(start_time, end_time)).
    returns([{
      :count => 1,
      :adv_amount => 1,
      :pub_amount => 1,
      :app_platform => 'iphone',
      :source => 'tj_games'
    }])

  VerticaCluster.
    expects(:query).
    once.
    with('analytics.actions', advertiser_options(start_time, end_time)).
    returns(adv_stats)

  VerticaCluster.
    expects(:query).
    once.
    with('analytics.actions', publisher_options(start_time, end_time)).
    returns(pub_stats)
end

def query_conditions(start_time, end_time)
  [
    "path LIKE '%reward%'",
    "time >= '#{start_time.to_s(:db)}'",
    "time < '#{end_time.to_s(:db)}'",
  ]
end

def currency(amount)
  NumberHelper.number_to_currency(amount / 100.0)
end

def percentage(value)
  NumberHelper.number_to_percentage((value || 0) * 100.0, :precision => 1)
end
