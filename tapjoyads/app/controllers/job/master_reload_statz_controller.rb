class Job::MasterReloadStatzController < Job::JobController
  include MemcachedHelper
  include ActionView::Helpers::NumberHelper
  
  def index
    now = Time.zone.now
    
    interval_strings = {}
    interval_strings['24_hours'] = "DATE_ADD(NOW(), INTERVAL -24 HOUR)"
    interval_strings['this_month'] = "curdate() - dayofmonth(now());"
    interval_strings['today'] = "curdate()"
    interval_strings['7_days'] = "DATE_ADD(NOW(), INTERVAL -7 DAY)"
    interval_strings['since_mar_23'] = "'2010-03-23'"
    interval_strings['1_month'] = "DATE_ADD(NOW(), INTERVAL -1 MONTH)"
    
    money_stats = {}
    
    interval_strings.keys.each do |is|      
      money_stats[is] = {}
      
      num_hours = Offer.count_by_sql("select HOUR(TIMEDIFF(now(), #{interval_strings[is]}))");
      
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
    
    cached_stats = {}
    
    apps = []
    SdbApp.select(:where => "interval_update_time = '3600'") do |app|
      apps.push(app)
    end

    apps.each do |app|
      appstats = Appstats.new(app.key, { :start_time => now - 23.hours, :end_time => now + 1.hour }).stats
      
      this_apps_stats = {}
      this_apps_stats['icon_url'] = app.get_icon_url
      this_apps_stats['app_name'] = app.name
      this_apps_stats['paid_installs'] = appstats['paid_installs'].sum
      this_apps_stats['connects'] = appstats['logins'].sum
      this_apps_stats['new_users'] = appstats['new_users'].sum
      this_apps_stats['daily_active_users'] = appstats['daily_active_users'].sum
      this_apps_stats['price'] = number_to_currency(app.price / 100.0)
      this_apps_stats['payment_for_install'] = number_to_currency(app.payment_for_install / 100.0)
      this_apps_stats['balance'] = number_to_currency(app.balance / 100.0)
      this_apps_stats['daily_budget'] = app.daily_budget
      this_apps_stats['show_rate'] = "%.2f" % (app.show_rate || 0)
      this_apps_stats['vg_purchases'] = appstats['vg_purchases'].sum
      this_apps_stats['published_installs'] = appstats['published_installs'].sum
      this_apps_stats['installs_revenue'] = number_to_currency(appstats['installs_revenue'].sum / 100.0)
      this_apps_stats['ad_impressions'] = appstats['hourly_impressions'].sum
      this_apps_stats['os_type'] = app.os_type
      
      cached_stats[app.key] = this_apps_stats
    end

    save_to_cache('statz.cached_stats', cached_stats)


    save_to_cache('statz.last_updated', now)
    
    render :text => 'ok'
  end
  
end