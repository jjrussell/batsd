class Job::MasterReloadMoneyController < Job::JobController
  include ActionView::Helpers::NumberHelper
  
  def index
    interval_strings = {}
    interval_strings['24_hours'] = "DATE_ADD(NOW(), INTERVAL -24 HOUR)"
    interval_strings['today'] = "CURDATE()"
    interval_strings['7_days'] = "DATE_ADD(NOW(), INTERVAL -7 DAY)"
    money_stats = get_money_stats(interval_strings)
    total_balance = Partner.sum(:balance, :conditions => "id != '70f54c6d-f078-426c-8113-d6e43ac06c6d'") / 100.0
    total_pending_earnings = Partner.sum(:pending_earnings, :conditions => "id != '70f54c6d-f078-426c-8113-d6e43ac06c6d'") / 100.0
    
    Mc.put('money.cached_stats', money_stats)
    Mc.put('money.total_balance', total_balance)
    Mc.put('money.total_pending_earnings', total_pending_earnings)
    Mc.put('money.last_updated', Time.zone.now)
    
    render :text => 'ok'
  end
  
  def daily
    interval_strings = {}
    interval_strings['this_month'] = "DATE(CURDATE() - DAYOFMONTH(NOW()) + 1)"
    interval_strings['1_month'] = "DATE_ADD(NOW(), INTERVAL -1 MONTH)"
    interval_strings['since_mar_23'] = "'2010-03-23'"
    interval_strings['this_year'] = "MAKEDATE(YEAR(CURDATE()), 1)"
    daily_money_stats = get_money_stats(interval_strings)
    
    Mc.put('money.daily_cached_stats', daily_money_stats)
    Mc.put('money.daily_last_updated', Time.zone.now)
    
    render :text => 'ok'
  end
  
private
  
  def get_money_stats(interval_strings)
    money_stats = {}
    
    interval_strings.keys.each do |is|
      money_stats[is] = {}
      
      num_hours = Offer.count_by_sql("SELECT DATEDIFF(NOW(), #{interval_strings[is]}) * 24 + HOUR(NOW()) - HOUR(#{interval_strings[is]})")
      
      conversions = Conversion.count(:conditions => "created_at > #{interval_strings[is]}")
      money_stats[is]['conversions'] = number_with_delimiter(conversions)
      
      advertiser_spend = Conversion.sum(:advertiser_amount, :conditions => "created_at > #{interval_strings[is]}") / -100.0      
      money_stats[is]['advertiser_spend'] = number_to_currency(advertiser_spend)
      
      publisher_earnings = Conversion.sum(:publisher_amount, 
        :conditions => "conversions.created_at > #{interval_strings[is]} AND partner_id != '70f54c6d-f078-426c-8113-d6e43ac06c6d'",
        :joins => "JOIN offers ON publisher_app_id = offers.id") / 100.0
      
      money_stats[is]['publisher_earnings'] = number_to_currency(publisher_earnings)  
        
      marketing_credits = Order.sum(:amount, :conditions => "created_at > #{interval_strings[is]} AND payment_method = 2") / 100.0
      money_stats[is]['marketing_credits'] = number_to_currency(marketing_credits)
      
      money_stats[is]['orders'] = number_to_currency(Order.sum(:amount, :conditions =>"created_at > #{interval_strings[is]} AND payment_method != 2") / 100.0)
      money_stats[is]['payouts'] = number_to_currency(Payout.sum(:amount, :conditions => "created_at > #{interval_strings[is]}") / 100.0)
      
      linkshare_est = conversions * 0.0138
      money_stats[is]['linkshare_est'] = number_to_currency(linkshare_est)
      
      ads_est = num_hours / 24.0 * 400.0
      money_stats[is]['ads_est'] = number_to_currency(ads_est)
      
      revenue = advertiser_spend - marketing_credits + linkshare_est + ads_est
      money_stats[is]['revenue'] = number_to_currency(revenue)
      money_stats[is]['net_revenue'] = number_to_currency(revenue - (publisher_earnings - marketing_credits * 0.7))
      money_stats[is]['margin'] = number_with_precision((revenue - (publisher_earnings - marketing_credits * 0.7)) / (revenue) * 100, :precision => 2) + "%"
    end
    
    return money_stats
  end
  
end
