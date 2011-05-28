class Job::MasterReloadMoneyController < Job::JobController
  include ActionView::Helpers::NumberHelper

  def index
    now = Time.zone.now

    total_balance, total_pending_earnings = nil
    Partner.using_slave_db do
      total_balance          = Partner.sum(:balance, :conditions => "id != '70f54c6d-f078-426c-8113-d6e43ac06c6d'") / 100.0
      total_pending_earnings = Partner.sum(:pending_earnings, :conditions => "id != '70f54c6d-f078-426c-8113-d6e43ac06c6d'") / 100.0
    end

    start_times               = {}
    start_times['24_hours']   = now - 24.hours
    start_times['7_days']     = now - 7.days
    start_times['1_month']    = now - 1.month
    start_times['today']      = now.beginning_of_day
    start_times['this_month'] = now.beginning_of_month
    start_times['this_year']  = now.beginning_of_year

    money_stats = get_money_stats(start_times, now)

    Mc.put('money.cached_stats', money_stats)
    Mc.put('money.total_balance', total_balance)
    Mc.put('money.total_pending_earnings', total_pending_earnings)
    Mc.put('money.last_updated', now.to_f)

    render :text => 'ok'
  end

private

  def get_money_stats(start_times, end_time)
    archive_cutoff = Conversion.archive_cutoff_time
    tj_partner = Partner.find('70f54c6d-f078-426c-8113-d6e43ac06c6d')
    stats = {}
    android_ids = App.by_platform('android').collect(&:id)
    ios_ids = App.by_platform('iphone').collect(&:id)
    tj_apps = tj_partner.app_ids

    Conversion.using_slave_db do
      start_times.each do |key, start_time|
        stats[key] = {}

        if start_time < archive_cutoff
          stats[key]['advertiser_spend'] = MonthlyAccounting.since(start_time).prior_to(archive_cutoff).sum(:spend)
          stats[key]['advertiser_spend'] += Conversion.created_between(archive_cutoff, end_time).sum(:advertiser_amount)

          stats[key]['publisher_earnings'] = MonthlyAccounting.since(start_time).prior_to(archive_cutoff).sum(:earnings, :conditions => ["partner_id != ?", tj_partner.id])
          stats[key]['publisher_earnings'] += Conversion.created_between(archive_cutoff, end_time).sum(:publisher_amount, :conditions => ["publisher_app_id NOT IN (?)", tj_partner.app_ids])

          stats[key]['android_conversions']  = '-'
          stats[key]['android_adv_spend']    = '-'
          stats[key]['android_pub_earnings'] = '-'
          stats[key]['ios_conversions']      = '-'
          stats[key]['ios_adv_spend']        = '-'
          stats[key]['ios_pub_earnings']     = '-'
        else
          stats[key]['conversions']        = Conversion.created_between(start_time, end_time).count(:conditions => ["reward_type < 1000 OR reward_type >= 2000"])
          stats[key]['advertiser_spend']   = Conversion.created_between(start_time, end_time).sum(:advertiser_amount)
          stats[key]['publisher_earnings'] = Conversion.created_between(start_time, end_time).sum(:publisher_amount, :conditions => ["publisher_app_id NOT IN (?)", tj_partner.app_ids])

          # stats[key]['android_conversions']  = Conversion.created_between(start_time, end_time).non_display.include_pub_apps(android_ids).count
          # stats[key]['android_adv_spend']    = Conversion.created_between(start_time, end_time).include_pub_apps(android_ids).sum(:advertiser_amount) / -100.0
          # stats[key]['android_pub_earnings'] = Conversion.created_between(start_time, end_time).exclude_pub_apps(tj_apps).include_pub_apps(android_ids).sum(:publisher_amount) / 100.0
          # stats[key]['ios_conversions']      = Conversion.created_between(start_time, end_time).non_display.include_pub_apps(ios_ids).count
          # stats[key]['ios_adv_spend']        = Conversion.created_between(start_time, end_time).include_pub_apps(ios_ids).sum(:advertiser_amount) / -100.0
          # stats[key]['ios_pub_earnings']     = Conversion.created_between(start_time, end_time).exclude_pub_apps(tj_apps).include_pub_apps(ios_ids).sum(:publisher_amount) / 100.0
          # 
          # stats[key]['android_conversions']  = number_with_delimiter(stats[key]['android_conversions'])
          # stats[key]['android_adv_spend']    = number_to_currency(stats[key]['android_adv_spend'])
          # stats[key]['android_pub_earnings'] = number_to_currency(stats[key]['android_pub_earnings'])
          # stats[key]['ios_conversions']      = number_with_delimiter(stats[key]['ios_conversions'])
          # stats[key]['ios_adv_spend']        = number_to_currency(stats[key]['ios_adv_spend'])
          # stats[key]['ios_pub_earnings']     = number_to_currency(stats[key]['ios_pub_earnings'])
          stats[key]['android_conversions']  = '-'
          stats[key]['android_adv_spend']    = '-'
          stats[key]['android_pub_earnings'] = '-'
          stats[key]['ios_conversions']      = '-'
          stats[key]['ios_adv_spend']        = '-'
          stats[key]['ios_pub_earnings']     = '-'
        end

        stats[key]['advertiser_spend']   /= -100.0
        stats[key]['publisher_earnings'] /=  100.0

        stats[key]['marketing_credits'] = Order.created_between(start_time, end_time).sum(:amount, :conditions => "payment_method = 2") / 100.0
        stats[key]['orders']            = Order.created_between(start_time, end_time).sum(:amount, :conditions => "payment_method != 2") / 100.0
        stats[key]['payouts']           = Payout.created_between(start_time, end_time).sum(:amount) / 100.0
        stats[key]['linkshare_est']     = stats[key]['advertiser_spend'] * 0.026
        stats[key]['ads_est']           = 0.0
        stats[key]['revenue']           = stats[key]['advertiser_spend'] - stats[key]['marketing_credits'] + stats[key]['linkshare_est'] + stats[key]['ads_est']
        stats[key]['net_revenue']       = stats[key]['revenue'] - stats[key]['publisher_earnings']
        stats[key]['margin']            = stats[key]['net_revenue'] / stats[key]['revenue'] * 100
        
        website_orders_deduction        = Order.created_between(start_time, end_time).sum(:amount, :conditions => "payment_method = 0") / 100.0 * 0.025
        stats[key]['deduct_pct']        = ( stats[key]['marketing_credits'] + website_orders_deduction ) / stats[key]['orders'] * 100

        stats[key]['conversions']        = stats[key]['conversions'].nil? ? '-' : number_with_delimiter(stats[key]['conversions'])
        stats[key]['advertiser_spend']   = number_to_currency(stats[key]['advertiser_spend'])
        stats[key]['publisher_earnings'] = number_to_currency(stats[key]['publisher_earnings'])
        stats[key]['marketing_credits']  = number_to_currency(stats[key]['marketing_credits'])
        stats[key]['deduct_pct']         = number_to_percentage(stats[key]['deduct_pct'], :precision => 2)
        stats[key]['orders']             = number_to_currency(stats[key]['orders'])
        stats[key]['payouts']            = number_to_currency(stats[key]['payouts'])
        stats[key]['linkshare_est']      = number_to_currency(stats[key]['linkshare_est'])
        stats[key]['ads_est']            = number_to_currency(stats[key]['ads_est'])
        stats[key]['revenue']            = number_to_currency(stats[key]['revenue'])
        stats[key]['net_revenue']        = number_to_currency(stats[key]['net_revenue'])
        stats[key]['margin']             = number_to_percentage(stats[key]['margin'], :precision => 2)
      end
    end

    stats
  end

end
