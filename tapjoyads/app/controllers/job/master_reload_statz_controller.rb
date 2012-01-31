class Job::MasterReloadStatzController < Job::JobController

  def index
    cache_stats('24_hours')

    render :text => 'ok'
  end

  def daily
    cache_stats('7_days')
    cache_stats('1_month')

    render :text => 'ok'
  end

  def partner_index
    cache_partners('24_hours')

    render :text => 'ok'
  end

  def partner_daily
    cache_partners('7_days')
    cache_partners('1_month')

    render :text => 'ok'
  end

  def devices_count
    count = Device.count
    Mc.put('statz.devices_count', count)

    render :text => 'ok'
  end

  private

  def cache_stats(timeframe)
    start_time, end_time = get_times_for_vertica(timeframe)
    time_conditions      = "time >= '#{start_time.to_s(:db)}' AND time < '#{end_time.to_s(:db)}'"

    cached_money = {
      :total    => { :count => 0, :adv_amount => 0, :pub_amount => 0, },
      :iphone   => { :count => 0, :adv_amount => 0, :pub_amount => 0, },
      :android  => { :count => 0, :adv_amount => 0, :pub_amount => 0, },
      :tj_games => { :count => 0, :adv_amount => 0, :pub_amount => 0, },
    }
    VerticaCluster.query('analytics.actions', {
        :select     => 'source, app_platform, count(path), -sum(advertiser_amount) as adv_amount, sum(publisher_amount) as pub_amount',
        :join       => 'analytics.apps_partners on actions.publisher_app_id = apps_partners.app_id',
        :conditions => "path = '[reward]' and app_platform != 'windows' and #{time_conditions}",
        :group      => 'source, app_platform' }).each do |result|
      cached_money[:total][:count] += result[:count]
      cached_money[:total][:adv_amount] += result[:adv_amount]
      cached_money[:total][:pub_amount] += result[:pub_amount]
      if result[:source] == 'tj_games'
        cached_money[:tj_games][:count] += result[:count]
        cached_money[:tj_games][:adv_amount] += result[:adv_amount]
        cached_money[:tj_games][:pub_amount] += result[:pub_amount]
      else
        cached_money[result[:app_platform].to_sym][:count] += result[:count]
        cached_money[result[:app_platform].to_sym][:adv_amount] += result[:adv_amount]
        cached_money[result[:app_platform].to_sym][:pub_amount] += result[:pub_amount]
      end
    end
    cached_money.each do |k, values|
      values[:count]      = NumberHelper.number_with_delimiter(values[:count])
      values[:adv_amount] = NumberHelper.number_to_currency(values[:adv_amount] / 100.0)
      values[:pub_amount] = NumberHelper.number_to_currency(values[:pub_amount] / 100.0)
    end

    cached_stats = {}
    VerticaCluster.query('analytics.actions', {
        :select     => 'offer_id, count(path) AS conversions, -sum(advertiser_amount) AS spend',
        :group      => 'offer_id',
        :conditions => "path LIKE '%reward%' AND #{time_conditions}" }).each do |result|
      cached_stats[result[:offer_id]] = {
        'conversions'       => NumberHelper.number_with_delimiter(result[:conversions]),
        'spend'             => NumberHelper.number_to_currency(result[:spend] / 100.0),
        'published_offers'  => '0',
        'gross_revenue'     => '$0.00',
        'publisher_revenue' => '$0.00',
      }
    end
    VerticaCluster.query('analytics.actions', {
        :select     => 'publisher_app_id AS offer_id, count(path) AS published_offers, sum(publisher_amount + tapjoy_amount) AS gross_revenue, sum(publisher_amount) AS publisher_revenue',
        :group      => 'publisher_app_id',
        :conditions => "path LIKE '%reward%' AND #{time_conditions}" }).each do |result|
      cached_stats[result[:offer_id]] ||= { 'conversions' => '0', 'spend' => '$0.00' }
      cached_stats[result[:offer_id]]['published_offers']  = NumberHelper.number_with_delimiter(result[:published_offers])
      cached_stats[result[:offer_id]]['gross_revenue']     = NumberHelper.number_to_currency(result[:gross_revenue] / 100.0)
      cached_stats[result[:offer_id]]['publisher_revenue'] = NumberHelper.number_to_currency(result[:publisher_revenue] / 100.0)
    end

    cached_metadata = {}
    Offer.find_each(:conditions => [ 'id IN (?)', cached_stats.keys ], :include => :partner) do |offer|
      cached_metadata[offer.id] = {
        'icon_url'           => offer.get_icon_url,
        'offer_name'         => offer.name_with_suffix,
        'price'              => NumberHelper.number_to_currency(offer.price / 100.0),
        'payment'            => NumberHelper.number_to_currency(offer.payment / 100.0),
        'balance'            => NumberHelper.number_to_currency(offer.partner.balance / 100.0),
        'conversion_rate'    => NumberHelper.number_to_percentage((offer.conversion_rate || 0) * 100.0, :precision => 1),
        'platform'           => offer.get_platform,
        'featured'           => offer.featured?,
        'rewarded'           => offer.rewarded?,
        'offer_type'         => offer.item_type,
        'overall_store_rank' => combined_ranks[offer.third_party_data] || '-',
        'sales_rep'          => offer.partner.sales_rep.to_s
      }
    end

    cached_stats_adv = cached_stats.sort do |s1, s2|
      NumberHelper.currency_to_number(s2[1]['spend']) <=> NumberHelper.currency_to_number(s1[1]['spend'])
    end
    cached_stats_pub = cached_stats.sort do |s1, s2|
      NumberHelper.currency_to_number(s2[1]['gross_revenue']) <=> NumberHelper.currency_to_number(s1[1]['gross_revenue'])
    end
    top_cached_stats = (cached_stats_adv.first(50) + cached_stats_pub.first(50)).uniq.sort do |s1, s2|
      NumberHelper.currency_to_number(s2[1]['spend']) <=> NumberHelper.currency_to_number(s1[1]['spend'])
    end
    top_offer_ids = Set.new(top_cached_stats.map { |pair| pair[0] })
    top_cached_metadata = cached_metadata.reject { |k, v| !top_offer_ids.include?(k) }

    Mc.distributed_put("statz.money.#{timeframe}", cached_money)
    Mc.distributed_put("statz.top_metadata.#{timeframe}", top_cached_metadata)
    Mc.distributed_put("statz.top_stats.#{timeframe}", top_cached_stats)
    Mc.distributed_put("statz.metadata.#{timeframe}", cached_metadata)
    Mc.distributed_put("statz.stats.#{timeframe}", cached_stats_adv)
    Mc.put("statz.last_updated_start.#{timeframe}", start_time.to_f)
    Mc.put("statz.last_updated_end.#{timeframe}", end_time.to_f)
  end

  def cache_partners(timeframe)
    start_time, end_time, granularity = get_times_for_appstats(timeframe)

    cached_partners = {}
    partner_ids = []
    Conversion.using_slave_db do
      conditions = "created_at >= '#{start_time.to_s(:db)}' AND created_at < '#{end_time.to_s(:db)}'"
      partner_ids |= Conversion.slave_connection.select_values("SELECT DISTINCT(publisher_partner_id)  FROM #{Conversion.quoted_table_name} WHERE #{conditions}")
      partner_ids |= Conversion.slave_connection.select_values("SELECT DISTINCT(advertiser_partner_id) FROM #{Conversion.quoted_table_name} WHERE #{conditions}")
    end

    partner_ids.each do |partner_id|
      partner = Partner.find(partner_id)
      ['partner', 'partner-ios', 'partner-android'].each do |prefix|
        stats            = Appstats.new(partner.id, { :start_time => start_time, :end_time => end_time, :granularity => granularity, :stat_prefix => prefix }).stats
        conversions      = stats['paid_installs'].sum
        published_offers = stats['rewards'].sum + stats['featured_published_offers'].sum + stats['display_conversions'].sum
        next unless conversions > 0 || published_offers > 0
        cached_partners[prefix] ||= {}
        cached_partners[prefix][partner.id] = partner_breakdowns(stats, partner)
      end
    end

    cached_partners.each do |key, breakdown|
      Mc.distributed_put("statz.#{key}.cached_stats.#{timeframe}", breakdown)
      Mc.put("statz.#{key}.last_updated_start.#{timeframe}", start_time.to_f)
      Mc.put("statz.#{key}.last_updated_end.#{timeframe}", end_time.to_f)
    end
  end

  def partner_breakdowns(stats, partner)

    partner_stats = {}

    # for advertisers and publishers pages
    partner_stats['partner']     = partner.name
    partner_stats['account_mgr'] = partner.account_managers.collect { |mgr| mgr.email }.compact.join(',')
    partner_stats['sales_rep']   = partner.sales_rep.to_s

    # for publishers page
    partner_stats['est_gross_revenue'] = NumberHelper.number_to_currency(stats['total_revenue'].sum / 100.0 / partner.rev_share)
    partner_stats['total_revenue']     = NumberHelper.number_to_currency(stats['total_revenue'].sum / 100.0)
    partner_stats['rev_share']         = NumberHelper.number_to_percentage(partner.rev_share * 100.0, :precision => 1)
    if stats['arpdau'].present?
      partner_stats['arpdau']          = NumberHelper.number_to_currency((stats['arpdau'].sum / 100.0) / (stats['arpdau'].length), :precision => 4)
    else
      partner_stats['arpdau']          = '-'
    end

    partner_stats['offerwall_views'] = NumberHelper.number_with_delimiter(stats['offerwall_views'].sum)
    partner_stats['featured_views']  = NumberHelper.number_with_delimiter(stats['featured_offers_shown'].sum)
    partner_stats['display_views']   = NumberHelper.number_with_delimiter(stats['display_ads_shown'].sum)

    partner_stats['offerwall_conversions'] = NumberHelper.number_with_delimiter(stats['rewards'].sum)
    partner_stats['featured_conversions']  = NumberHelper.number_with_delimiter(stats['featured_published_offers'].sum)
    partner_stats['display_conversions']   = NumberHelper.number_with_delimiter(stats['display_conversions'].sum)

    partner_stats['offerwall_revenue'] = NumberHelper.number_to_currency(stats['rewards_revenue'].sum / 100.0)
    partner_stats['featured_revenue']  = NumberHelper.number_to_currency(stats['featured_revenue'].sum / 100.0)
    partner_stats['display_revenue']   = NumberHelper.number_to_currency(stats['display_revenue'].sum / 100.0)

    rewards_opened = stats['rewards_opened'].sum
    if rewards_opened == 0
      partner_stats['offerwall_cvr'] = 0
    else
      partner_stats['offerwall_cvr'] = NumberHelper.number_to_percentage(stats['rewards'].sum.to_f / rewards_opened.to_f * 100.0, :precision => 1)
    end

    featured_offers_opened = stats['featured_offers_opened'].sum
    if featured_offers_opened == 0
      partner_stats['featured_cvr'] = 0
    else
      partner_stats['featured_cvr'] = NumberHelper.number_to_percentage(stats['featured_published_offers'].sum.to_f / featured_offers_opened.to_f * 100.0, :precision => 1)
    end

    display_clicks = stats['display_clicks'].sum
    if display_clicks == 0
      partner_stats['display_cvr'] = 0
    else
      partner_stats['display_cvr'] = NumberHelper.number_to_percentage(stats['display_conversions'].sum.to_f / display_clicks.to_f * 100.0, :precision => 1)
    end

    partner_stats['offerwall_ecpm'] = NumberHelper.number_to_currency((stats['rewards_revenue'].sum / 100.0) / (stats['offerwall_views'].sum / 1000.0))
    partner_stats['featured_ecpm']  = NumberHelper.number_to_currency((stats['featured_revenue'].sum / 100.0) / (stats['featured_offers_shown'].sum / 1000.0))
    partner_stats['display_ecpm']   = NumberHelper.number_to_currency((stats['display_revenue'].sum / 100.0) / (stats['display_ads_shown'].sum / 1000.0))

    # for advertisers page
    partner_stats['spend']   = NumberHelper.number_to_currency(-stats['installs_spend'].sum / 100.0)
    partner_stats['balance'] = NumberHelper.number_to_currency(partner.balance / 100.0)

    partner_stats['clicks']        = NumberHelper.number_with_delimiter(stats['paid_clicks'].sum)
    partner_stats['paid_installs'] = NumberHelper.number_with_delimiter(stats['paid_installs'].sum)

    paid_clicks = stats['paid_clicks'].sum
    if paid_clicks == 0
      partner_stats['cvr'] = 0
    else
      partner_stats['cvr'] = NumberHelper.number_to_percentage((stats['paid_installs'].sum.to_f / paid_clicks.to_f) * 100.0, :precision => 1)
    end

    partner_stats['sessions']  = NumberHelper.number_with_delimiter(stats['logins'].sum)
    partner_stats['new_users'] = NumberHelper.number_with_delimiter(stats['new_users'].sum)

    partner_stats
  end

  def get_times_for_vertica(timeframe)
    most_recent = VerticaCluster.query('analytics.actions', :select => 'max(time)').first[:max]

    if timeframe == '24_hours'
      end_time   = most_recent - (most_recent.to_i % 10.minutes).seconds
      start_time = end_time - 24.hours
    elsif timeframe == '7_days'
      end_time   = most_recent.beginning_of_day
      start_time = end_time - 7.days
    elsif timeframe == '1_month'
      end_time   = most_recent.beginning_of_day
      start_time = end_time - 30.days
    end

    [ start_time, end_time ]
  end

  def get_times_for_appstats(timeframe)
    now = Time.zone.now
    granularity = timeframe == '24_hours' ? :hourly : :daily

    if timeframe == '24_hours'
      end_time   = now.beginning_of_hour
      start_time = end_time - 24.hours
    elsif timeframe == '7_days'
      end_time   = now.beginning_of_day
      start_time = end_time - 7.days
    elsif timeframe == '1_month'
      end_time   = now.beginning_of_day
      start_time = end_time - 30.days
    end

    [ start_time, end_time, granularity ]
  end

  def combined_ranks
    @combined_ranks ||= begin
      ios_ranks_free     = Mc.get('store_ranks.ios.overall.free.united_states') || {}
      ios_ranks_paid     = Mc.get('store_ranks.ios.overall.paid.united_states') || {}
      android_ranks_free = Mc.get('store_ranks.android.overall.free.english')   || {}
      android_ranks_paid = Mc.get('store_ranks.android.overall.paid.english')   || {}

      ios_ranks_free.merge(ios_ranks_paid).merge(android_ranks_free).merge(android_ranks_paid)
    end
  end

end
