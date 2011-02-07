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
  
private
  
  def cache_stats(timeframe)
    now = Time.zone.now
    
    cached_stats = {}
    
    granularity = timeframe == '24_hours' ? :hourly : :daily
    start_time = now - 23.hours
    if timeframe == '7_days'
      start_time = now - 7.days
    elsif timeframe == '1_month'
      start_time = now - 30.days
    end
    
    Offer.find_each(:conditions => "stats_aggregation_interval = 3600") do |offer|
      appstats = Appstats.new(offer.id, { :start_time => start_time, :end_time => now + 1.hour, :granularity => granularity }).stats
      conversions = appstats['paid_installs'].sum
      published_offers = appstats['rewards'].sum
      next unless conversions > 0 || published_offers > 0
      
      this_apps_stats = {}
      this_apps_stats['icon_url'] = offer.get_icon_url
      this_apps_stats['offer_name'] = offer.name_with_suffix
      this_apps_stats['conversions'] = number_with_delimiter(conversions)
      this_apps_stats['connects'] = number_with_delimiter(appstats['logins'].sum)
      this_apps_stats['overall_store_rank'] = (Array(appstats['ranks']['overall.free.united_states']).find_all{|r| r != nil}.last || '-')
      this_apps_stats['price'] = number_to_currency(offer.price / 100.0)
      this_apps_stats['payment'] = number_to_currency(offer.payment / 100.0)
      this_apps_stats['balance'] = number_to_currency(offer.partner.balance / 100.0)
      this_apps_stats['conversion_rate'] = "%.1f%" % ((offer.conversion_rate || 0) * 100.0)
      this_apps_stats['published_offers'] = number_with_delimiter(published_offers)
      this_apps_stats['offers_revenue'] = number_to_currency(appstats['rewards_revenue'].sum / 100.0)
      this_apps_stats['platform'] = offer.get_platform
      this_apps_stats['featured'] = offer.featured?
      
      cached_stats[offer.id] = this_apps_stats
      
      if timeframe != '24_hours'
        sleep(1)
      end
    end
    
    cached_stats = cached_stats.sort do |s1, s2|
      s2[1]['conversions'] <=> s1[1]['conversions']
    end
    
    Mc.distributed_put("statz.cached_stats.#{timeframe}", cached_stats)
    Mc.put("statz.last_updated.#{timeframe}", now.to_f)
  end
  
end
