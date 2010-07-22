class Job::MasterReloadStatzController < Job::JobController
  include ActionView::Helpers::NumberHelper
  
  def index
    now = Time.zone.now
    
    cached_stats = {}
    
    Offer.find(:all, :conditions => "stats_aggregation_interval = 3600").each do |offer|
      appstats = Appstats.new(offer.id, { :start_time => now - 23.hours, :end_time => now + 1.hour }).stats
      
      this_apps_stats = {}
      this_apps_stats['icon_url'] = offer.get_icon_url
      this_apps_stats['offer_name'] = offer.name
      this_apps_stats['conversions'] = appstats['paid_installs'].sum
      this_apps_stats['connects'] = appstats['logins'].sum
      this_apps_stats['overall_store_rank'] = (appstats['overall_store_rank'].find_all{|r| r != '0'}.last || '-')
      this_apps_stats['price'] = number_to_currency(offer.price / 100.0)
      this_apps_stats['payment'] = number_to_currency(offer.payment / 100.0)
      this_apps_stats['balance'] = number_to_currency(offer.partner.balance / 100.0)
      this_apps_stats['pending_earnings'] = number_to_currency(offer.partner.pending_earnings / 100.0)
      this_apps_stats['daily_budget'] = offer.daily_budget
      this_apps_stats['show_rate'] = "%.1f%" % ((offer.show_rate || 0) * 100.0)
      this_apps_stats['conversion_rate'] = "%.1f%" % ((offer.conversion_rate || 0) * 100.0)
      this_apps_stats['vg_purchases'] = appstats['vg_purchases'].sum
      this_apps_stats['published_installs'] = appstats['published_installs'].sum
      this_apps_stats['installs_revenue'] = number_to_currency(appstats['installs_revenue'].sum / 100.0)
      this_apps_stats['ad_impressions'] = appstats['hourly_impressions'].sum
      this_apps_stats['platform'] = offer.get_platform
      
      cached_stats[offer.id] = this_apps_stats
    end

    Mc.put('statz.cached_stats', cached_stats)
    Mc.put('statz.last_updated', now)
    
    render :text => 'ok'
  end
  
end
