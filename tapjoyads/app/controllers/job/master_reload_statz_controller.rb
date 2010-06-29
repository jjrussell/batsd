class Job::MasterReloadStatzController < Job::JobController
  include MemcachedHelper
  include ActionView::Helpers::NumberHelper
  
  def index
    now = Time.zone.now
    
    interval_strings = {}
    interval_strings['24_hours'] = "DATE_ADD(NOW(), INTERVAL -24 HOUR)"
    interval_strings['this_month'] = "DATE(curdate() - dayofmonth(now()) + 1)"
    interval_strings['today'] = "curdate()"
    interval_strings['7_days'] = "DATE_ADD(NOW(), INTERVAL -7 DAY)"
    interval_strings['since_mar_23'] = "'2010-03-23'"
    interval_strings['1_month'] = "DATE_ADD(NOW(), INTERVAL -1 MONTH)"
    
    money_stats = {}
    
    interval_strings.keys.each do |is|      
      money_stats[is] = {}
      
      num_hours = Offer.count_by_sql("select DATEDIFF(now(), #{interval_strings[is]})*24 + HOUR(NOW()) - HOUR(#{interval_strings[is]})");
      
      conversions = Conversion.count(:conditions => "created_at > #{interval_strings[is]}")
      money_stats[is]['conversions'] = number_with_delimiter(conversions)
      
      advertiser_spend = Conversion.sum(:advertiser_amount, :conditions => "created_at > #{interval_strings[is]}")/-100.0      
      money_stats[is]['advertiser_spend'] = number_to_currency(advertiser_spend)
      
      publisher_earnings = Conversion.sum(:publisher_amount, 
        :conditions => "conversions.created_at > #{interval_strings[is]} and partner_id != '70f54c6d-f078-426c-8113-d6e43ac06c6d'",
        :joins => "JOIN offers on publisher_app_id = offers.id")/100.0
      
      money_stats[is]['publisher_earnings'] = number_to_currency(publisher_earnings)  
        
      marketing_credits = Order.sum(:amount, :conditions => "created_at > #{interval_strings[is]} and payment_method = 2")/100.0
      money_stats[is]['marketing_credits'] = number_to_currency(marketing_credits)
      
      money_stats[is]['orders'] = number_to_currency(Order.sum(:amount, :conditions =>"created_at > #{interval_strings[is]} and payment_method != 2")/100.0)
      money_stats[is]['payouts'] = number_to_currency(Payout.sum(:amount, :conditions => "created_at > #{interval_strings[is]}")/100.0)
      
      linkshare_est = conversions * 0.0123
      money_stats[is]['linkshare_est'] = number_to_currency(linkshare_est)
      
      ads_est = num_hours / 24.0 * 400.0
      money_stats[is]['ads_est'] = number_to_currency(ads_est)
      
      revenue = advertiser_spend - marketing_credits + linkshare_est + ads_est
      money_stats[is]['revenue'] = number_to_currency(revenue)
      money_stats[is]['net_revenue'] = number_to_currency(revenue - (publisher_earnings - marketing_credits*0.7))
      money_stats[is]['margin'] = number_with_precision((revenue - (publisher_earnings - marketing_credits*0.7)) / (revenue) * 100, :precision => 2) + "%"
      
    end
    
    save_to_cache('statz.money', money_stats)
    
    total_balance = Partner.sum(:balance, :conditions => "id != '70f54c6d-f078-426c-8113-d6e43ac06c6d'") / 100.0
    total_pending_earnings = Partner.sum(:pending_earnings, :conditions => "id != '70f54c6d-f078-426c-8113-d6e43ac06c6d'") / 100.0
    
    save_to_cache('statz.balance', total_balance)
    save_to_cache('statz.pending_earnings', total_pending_earnings)
    
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

    save_to_cache('statz.cached_stats', cached_stats)


    save_to_cache('statz.last_updated', now)
    
    render :text => 'ok'
  end
  
end