require 'spec/spec_helper'

describe Job::MasterReloadStatzController do
  before :each do
    Time.zone.stubs(:now).returns(Time.zone.parse('2011-02-15'))
    @start_time = Time.zone.now - 1.day
    @end_time = Time.zone.now
    @controller.expects(:authenticate).at_least_once.returns(true)
  end

  describe '#index' do
    it 'saves memcache values' do
      100.times { Factory(:email_offer) }
      stub_vertica
      get(:index)

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

    it 'generates weekly and monthly timeframes' do
      start_time = Time.zone.now - 7.days
      end_time = Time.zone.now

      stub_vertica(start_time, end_time)

      start_time = Time.zone.now - 30.days
      end_time = Time.zone.now

      stub_vertica(start_time, end_time)

      get(:daily)

      response.body.should == 'ok'
    end

    it 'generates combined ranks' do
      apps = [
        Factory(:app,
          :store_id => 'ios.free',
          :platform => 'iphone',
          :price => 0),
        Factory(:app,
          :store_id => 'ios.paid',
          :platform => 'iphone',
          :price => 1),
        Factory(:app,
          :store_id => 'android.free',
          :platform => 'android',
          :price => 0),
        Factory(:app,
          :store_id => 'android.paid',
          :platform => 'android',
          :price => 1),
      ]

      stub_vertica

      hash = {'ios.free' => [1]}
      Mc.put('store_ranks.ios.overall.free.united_states', hash)
      hash = {'ios.paid' => [1]}
      Mc.put('store_ranks.ios.overall.paid.united_states', hash)
      hash = {'android.free' => [1]}
      Mc.put('store_ranks.android.overall.free.english', hash)
      hash = {'android.paid' => [1]}
      Mc.put('store_ranks.android.overall.paid.english', hash)

      get(:index)

      metadata = Mc.get("statz.metadata.24_hours")
      apps.each do |app|
        metadata[app.id]['overall_store_rank'].should == [1]
      end
    end
  end

  describe '#partner_index' do
    before :each do
      @partner = Factory(:partner)

      @mock_appstats = mock()
      @mock_appstats.stubs(:stats).returns(stats_hash)
    end

    it 'saves partner values' do
      stub_conversions
      stub_appstats

      get(:partner_index)

      expected_stats = {
        "account_mgr"           => "",
        "balance"               => "$0.00",
        "clicks"                => "600",
        "cvr"                   => "100.0%",
        "display_conversions"   => "600",
        "display_cvr"           => "100.0%",
        "display_ecpm"          => "$10.00",
        "display_revenue"       => "$6.00",
        "display_views"         => "600",
        "est_gross_revenue"     => "$12.00",
        "featured_conversions"  => "600",
        "featured_cvr"          => "100.0%",
        "featured_ecpm"         => "$10.00",
        "featured_revenue"      => "$6.00",
        "featured_views"        => "600",
        "new_users"             => "600",
        "offerwall_conversions" => "600",
        "offerwall_cvr"         => "100.0%",
        "offerwall_ecpm"        => "$10.00",
        "offerwall_revenue"     => "$6.00",
        "offerwall_views"       => "600",
        "paid_installs"         => "600",
        "partner"               => @partner.name,
        "rev_share"             => "50.0%",
        "sales_rep"             => "",
        "sessions"              => "600",
        "spend"                 => "$-6.00",
        "total_revenue"         => "$6.00",
        "arpdau"                => "-",
      }

      actual_stats = Mc.get('statz.partner.cached_stats.24_hours')
      partner_stats = actual_stats[@partner.id]
      partner_stats.should == expected_stats

      partner_keys = [ 'partner', 'partner-ios', 'partner-android' ]
      partner_keys.each do |key|
        start_time = Mc.get("statz.#{key}.last_updated_start.24_hours")
        start_time.should == @start_time.to_f
        end_time = Mc.get("statz.#{key}.last_updated_end.24_hours")
        end_time.should == @end_time.to_f
      end

      response.body.should == 'ok'
    end

    it 'displays 0 for cvr without percentage' do
      stub_conversions

      zero_keys = [
        'rewards_opened',
        'featured_offers_opened',
        'display_clicks',
        'paid_clicks',
      ]
      zero_hash = {}
      zero_keys.each { |key| zero_hash[key] = [0] }

      @mock_appstats.stubs(:stats).returns(stats_hash.merge(zero_hash))
      stub_appstats

      zero_keys = [
        'offerwall_cvr',
        'featured_cvr',
        'display_cvr',
        'cvr',
      ]

      get :partner_index

      cached_stats = Mc.get('statz.partner.cached_stats.24_hours')
      partner_stats = cached_stats[@partner.id]
      zero_keys.each do |key|
        partner_stats[key].should == 0
      end
    end

    it 'generates weekly and monthly timeframes' do
      start_time = Time.zone.now - 7.days
      end_time = Time.zone.now

      stub_conversions(start_time, end_time)
      stub_appstats(:daily)

      start_time = Time.zone.now - 30.days
      end_time = Time.zone.now

      stub_conversions(start_time, end_time)
      stub_appstats(:daily)

      get :partner_daily
      response.body.should == 'ok'
    end

    it 'stores partner metadata' do
      stub_conversions
      stub_appstats

      admin_user = Factory(:admin)
      admin_user2 = Factory(:admin)

      @partner.account_managers = [admin_user, admin_user2]
      @partner.sales_rep = admin_user
      @partner.balance = 1000
      @partner.save!

      get :partner_index
      cached_stats = Mc.get('statz.partner.cached_stats.24_hours')
      partner_stats = cached_stats[@partner.id]
      partner_stats['partner'].should == @partner.name

      emails = [admin_user.email, admin_user2.email]
      partner_stats['account_mgr'].split(',').sort.should == emails.sort
      partner_stats['sales_rep'].should == admin_user.email
      partner_stats['balance'].should == '$10.00'
    end

    it 'does not skip if published_offers > 0' do
      stub_conversions

      get :partner_index
      Mc.get('statz.partner.cached_stats.24_hours').should be_nil

      hash = stats_hash.merge('paid_installs' => [0])
      @mock_appstats.stubs(:stats).returns(hash)
      stub_appstats

      get :partner_index
      cached_stats = Mc.get('statz.partner.cached_stats.24_hours')
      cached_stats.keys.should include @partner.id
    end

    it 'does not skip if conversions > 0' do
      stub_conversions

      get :partner_index
      Mc.get('statz.partner.cached_stats.24_hours').should be_nil

      zero_hash = {
        'rewards' => [0],
        'featured_published_offers' => [0],
        'display_conversions' => [0],
      }

      @mock_appstats.stubs(:stats).returns(stats_hash.merge(zero_hash))
      stub_appstats

      get :partner_index
      cached_stats   = Mc.get('statz.partner.cached_stats.24_hours')
      cached_ios     = Mc.get('statz.partner-ios.cached_stats.24_hours')
      cached_android = Mc.get('statz.partner-android.cached_stats.24_hours')

      cached_stats.keys.should   include @partner.id
      cached_ios.keys.should     include @partner.id
      cached_android.keys.should include @partner.id
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

def stats_hash
  return @hash if @hash
  @hash = {}
  stats_keys.each do |key|
    @hash[key] = [100,200,300]
  end
  @hash
end

def stats_keys
  @keys ||= Stats::CONVERSION_STATS + Stats::WEB_REQUEST_STATS +
    [
      'cvr',
      'rewards',
      'rewards_opened',
      'rewards_revenue',
      'rewards_ctr',
      'rewards_cvr',
      'offerwall_ecpm',
      'featured_ctr',
      'featured_cvr',
      'featured_fill_rate',
      'featured_ecpm',
      'display_fill_rate',
      'display_ctr', 'display_cvr',
      'display_ecpm',
      'non_display_revenue',
      'total_revenue',
      'daily_active_users'
    ]
end

def conversion_query(partner_type, start_time, end_time)
  insert = partner_type == 'publisher' ? ' ' : ''
  "SELECT DISTINCT(#{partner_type}_partner_id) #{insert}" +
    "FROM #{Conversion.quoted_table_name} " +
    "WHERE created_at >= '#{start_time.to_s(:db)}' " +
      "AND created_at < '#{end_time.to_s(:db)}'"
end

def currency(amount)
  NumberHelper.number_to_currency(amount / 100.0)
end

def percentage(value)
  NumberHelper.number_to_percentage((value || 0) * 100.0, :precision => 1)
end

def stub_appstats(granularity = :hourly)
  Appstats.expects(:new).
    times(3).
    with(@partner.id, has_entry(:granularity, granularity)).
    returns(@mock_appstats)
end

def stub_conversions(start_time = nil, end_time = nil)
  start_time ||= @start_time
  end_time ||= @end_time
  Conversion.slave_connection.
    expects(:select_values).
    with(conversion_query('publisher', start_time, end_time)).
    at_least(1).
    returns([@partner.id])

  Conversion.slave_connection.
    expects(:select_values).
    with(conversion_query('advertiser', start_time, end_time)).
    at_least(1).
    returns([@partner.id])
end
