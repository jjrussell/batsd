class Job::MasterReloadStatzController < Job::JobController
  include ActionView::Helpers::NumberHelper

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

private

  def cache_stats(timeframe)
    now, granularity, start_time = get_times(timeframe)

    cached_stats    = {}
    cached_metadata = {}
    find_options    = timeframe == '24_hours' ? { :conditions => 'active = true' } : {}
    Offer.find_each(find_options) do |offer|
      appstats         = Appstats.new(offer.id, { :start_time => start_time, :end_time => now + 1.hour, :granularity => granularity }).stats
      conversions      = appstats['paid_installs'].sum
      published_offers = appstats['rewards'].sum + appstats['featured_published_offers'].sum + appstats['display_conversions'].sum
      connects         = appstats['logins'].sum
      next unless conversions > 0 || published_offers > 0 || (offer.item_type == 'ActionOffer' && connects > 0)

      metadata = {}
      metadata['icon_url']        = offer.get_icon_url
      metadata['offer_name']      = offer.name_with_suffix
      metadata['price']           = number_to_currency(offer.price / 100.0)
      metadata['payment']         = number_to_currency(offer.payment / 100.0)
      metadata['balance']         = number_to_currency(offer.partner.balance / 100.0)
      metadata['conversion_rate'] = "%.1f%" % ((offer.conversion_rate || 0) * 100.0)
      metadata['platform']        = offer.get_platform
      metadata['featured']        = offer.featured?
      metadata['rewarded']        = offer.rewarded?
      metadata['offer_type']      = offer.item_type
      metadata['sales_rep']       = offer.partner.sales_rep.to_s

      stats = {}
      stats['conversions']        = number_with_delimiter(conversions)
      stats['connects']           = number_with_delimiter(appstats['logins'].sum)
      stats['published_offers']   = number_with_delimiter(published_offers)
      stats['offers_revenue']     = number_to_currency(appstats['total_revenue'].sum / 100.0)
      region                      = offer.get_device_types.include?('android') ? 'english' : 'united_states'
      price                       = offer.is_paid? ? 'paid' : 'free'
      stats['overall_store_rank'] = (Array(appstats['ranks']["overall.#{price}.#{region}"]).find_all{ |r| r != nil }.last || '-')

      cached_metadata[offer.id] = metadata
      cached_stats[offer.id]    = stats
    end

    cached_stats = cached_stats.sort do |s1, s2|
      s2[1]['conversions'].gsub(',', '').to_i <=> s1[1]['conversions'].gsub(',', '').to_i
    end

    Mc.distributed_put("statz.metadata.#{timeframe}", cached_metadata)
    Mc.distributed_put("statz.stats.#{timeframe}", cached_stats)
    Mc.put("statz.last_updated.#{timeframe}", now.to_f)
  end

  def cache_partners(timeframe)
    now, granularity, start_time = get_times(timeframe)

    cached_partners = {}

    find_options = timeframe == '24_hours' ? { :joins => :offers, :conditions => 'active = true' } : {}
    Partner.find_each(find_options) do |partner|
      ['partner', 'partner-ios', 'partner-android'].each do |prefix|
        stats            = Appstats.new(partner.id, { :start_time => start_time, :end_time => now + 1.hour, :granularity => granularity, :stat_prefix => prefix }).stats
        conversions      = stats['paid_installs'].sum
        published_offers = stats['rewards'].sum + stats['featured_published_offers'].sum + stats['display_conversions'].sum
        next unless conversions > 0 || published_offers > 0
        cached_partners[prefix] ||= {}
        cached_partners[prefix][partner.id] = partner_breakdowns(stats, partner)
      end
    end

    cached_partners.each do |key, breakdown|
      breakdown = breakdown.sort do |s1, s2|
        s2[1]['total_revenue'].gsub(',', '').gsub('$', '').to_i <=> s1[1]['total_revenue'].gsub(',', '').gsub('$', '').to_i
      end
      Mc.distributed_put("statz.#{key}.cached_stats.#{timeframe}", breakdown)
      Mc.put("statz.#{key}.last_updated.#{timeframe}", now.to_f)
    end
  end

  def partner_breakdowns(stats, partner)

    partner_stats = {}

    # for advertisers and publishers pages
    partner_stats['partner']     = partner.name
    partner_stats['account_mgr'] = partner.account_managers.collect { |mgr| mgr.email }.compact.join(',')
    partner_stats['sales_rep']   = partner.sales_rep.to_s

    # for publishers page
    partner_stats['total_revenue'] = number_to_currency(stats['total_revenue'].sum / 100.0)
    partner_stats['rev_share']     = number_to_percentage(partner.rev_share * 100.0, :precision => 1)

    partner_stats['offerwall_views'] = number_with_delimiter(stats['offerwall_views'].sum)
    partner_stats['featured_views']  = number_with_delimiter(stats['featured_offers_shown'].sum)
    partner_stats['display_views']   = number_with_delimiter(stats['display_ads_shown'].sum)

    partner_stats['offerwall_conversions'] = number_with_delimiter(stats['rewards'].sum)
    partner_stats['featured_conversions']  = number_with_delimiter(stats['featured_published_offers'].sum)
    partner_stats['display_conversions']   = number_with_delimiter(stats['display_conversions'].sum)

    partner_stats['offerwall_revenue'] = number_to_currency(stats['rewards_revenue'].sum / 100.0)
    partner_stats['featured_revenue']  = number_to_currency(stats['featured_revenue'].sum / 100.0)
    partner_stats['display_revenue']   = number_to_currency(stats['display_revenue'].sum / 100.0)

    rewards_opened = stats['rewards_opened'].sum
    if rewards_opened == 0
      partner_stats['offerwall_cvr'] = 0
    else
      partner_stats['offerwall_cvr'] = number_to_percentage(stats['rewards'].sum.to_f / rewards_opened.to_f * 100.0, :precision => 1)
    end

    featured_offers_opened = stats['featured_offers_opened'].sum
    if featured_offers_opened == 0
      partner_stats['featured_cvr'] = 0
    else
      partner_stats['featured_cvr'] = number_to_percentage(stats['featured_published_offers'].sum.to_f / featured_offers_opened.to_f * 100.0, :precision => 1)
    end

    display_clicks = stats['display_clicks'].sum
    if display_clicks == 0
      partner_stats['display_cvr'] = 0
    else
      partner_stats['display_cvr'] = number_to_percentage(stats['display_conversions'].sum.to_f / display_clicks.to_f * 100.0, :precision => 1)
    end

    partner_stats['offerwall_ecpm'] = number_to_currency((stats['rewards_revenue'].sum / 100.0) / (stats['offerwall_views'].sum / 1000.0))
    partner_stats['featured_ecpm']  = number_to_currency((stats['featured_revenue'].sum / 100.0) / (stats['featured_offers_shown'].sum / 1000.0))
    partner_stats['display_ecpm']   = number_to_currency((stats['display_revenue'].sum / 100.0) / (stats['display_ads_shown'].sum / 1000.0))

    # for advertisers page
    partner_stats['spend']   = number_to_currency(stats['installs_spend'].sum / 100.0)
    partner_stats['balance'] = number_to_currency(partner.balance / 100.0)

    partner_stats['clicks']        = number_with_delimiter(stats['paid_clicks'].sum)
    partner_stats['paid_installs'] = number_with_delimiter(stats['paid_installs'].sum)

    paid_clicks = stats['paid_clicks'].sum
    if paid_clicks == 0
      partner_stats['cvr'] = 0
    else
      partner_stats['cvr'] = number_to_percentage((stats['paid_installs'].sum.to_f / paid_clicks.to_f) * 100.0, :precision => 1)
    end

    partner_stats['sessions']  = number_with_delimiter(stats['logins'].sum)
    partner_stats['new_users'] = number_with_delimiter(stats['new_users'].sum)

    partner_stats
  end

  def get_times(timeframe)
    now = Time.zone.now

    granularity = timeframe == '24_hours' ? :hourly : :daily
    start_time = now - 23.hours
    if timeframe == '7_days'
      start_time = now - 7.days
    elsif timeframe == '1_month'
      start_time = now - 30.days
    end

    return now, granularity, start_time
  end
end
