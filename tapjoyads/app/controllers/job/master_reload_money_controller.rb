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

    money_stats = get_money_stats(start_times, now)

    Mc.put('money.cached_stats', money_stats)
    Mc.put('money.total_balance', total_balance)
    Mc.put('money.total_pending_earnings', total_pending_earnings)
    Mc.put('money.last_updated', now.to_f)

    render :text => 'ok'
  end

  def daily
    now = Time.zone.now

    start_times                 = {}
    start_times['since_mar_23'] = Time.zone.parse("2010-03-23")
    start_times['this_year']    = now.beginning_of_year

    daily_money_stats = get_money_stats(start_times, now)

    Mc.put('money.daily_cached_stats', daily_money_stats)
    Mc.put('money.daily_last_updated', now.to_f)

    render :text => 'ok'
  end

private

  def get_money_stats(start_times, end_time)
    archive_cutoff = Conversion.archive_cutoff_time
    tj_partner = Partner.find('70f54c6d-f078-426c-8113-d6e43ac06c6d')
    stats = {}

    Conversion.using_slave_db do
      start_times.each do |key, start_time|
        stats[key] = {}

        if start_time < archive_cutoff
          stats[key]['conversions'] = MonthlyAccounting.since(start_time).prior_to(archive_cutoff).count
          stats[key]['conversions'] += Conversion.created_between(archive_cutoff, end_time).count

          stats[key]['advertiser_spend'] = MonthlyAccounting.since(start_time).prior_to(archive_cutoff).sum(:spend)
          stats[key]['advertiser_spend'] += Conversion.created_between(archive_cutoff, end_time).sum(:advertiser_amount)

          stats[key]['publisher_earnings'] = MonthlyAccounting.since(start_time).prior_to(archive_cutoff).sum(:spend, :conditions => ["partner_id != ?", tj_partner.id])
          stats[key]['publisher_earnings'] += Conversion.created_between(archive_cutoff, end_time).sum(:advertiser_amount, :conditions => ["publisher_app_id NOT IN (?)", tj_partner.app_ids])
        else
          stats[key]['conversions']        = Conversion.created_between(start_time, end_time).count
          stats[key]['advertiser_spend']   = Conversion.created_between(start_time, end_time).sum(:advertiser_amount)
          stats[key]['publisher_earnings'] = Conversion.created_between(start_time, end_time).sum(:advertiser_amount, :conditions => ["publisher_app_id NOT IN (?)", tj_partner.app_ids])
        end
        stats[key]['advertiser_spend']   /= -100.0
        stats[key]['publisher_earnings'] /=  100.0

        stats[key]['marketing_credits'] = Order.created_between(start_time, end_time).sum(:amount, :conditions => "payment_method = 2") / 100.0
        stats[key]['orders']            = Order.created_between(start_time, end_time).sum(:amount, :conditions => "payment_method != 2") / 100.0
        stats[key]['payouts']           = Payout.created_between(start_time, end_time).sum(:amount) / 100.0
        stats[key]['linkshare_est']     = stats[key]['conversions'] * 0.0104
        stats[key]['ads_est']           = ((end_time - start_time) / 3600).to_i / 24.0 * 400.0
        stats[key]['revenue']           = stats[key]['advertiser_spend'] - stats[key]['marketing_credits'] + stats[key]['linkshare_est'] + stats[key]['ads_est']
        stats[key]['net_revenue']       = stats[key]['revenue'] - (stats[key]['publisher_earnings'] - stats[key]['marketing_credits'] * 0.7)
        stats[key]['margin']            = stats[key]['net_revenue'] / stats[is]['revenue'] * 100

        stats[key]['conversions']        = number_with_delimiter(stats[key]['conversions'])
        stats[key]['advertiser_spend']   = number_to_currency(stats[key]['advertiser_spend'])
        stats[key]['publisher_earnings'] = number_to_currency(stats[key]['publisher_earnings'])
        stats[key]['marketing_credits']  = number_to_currency(stats[key]['marketing_credits'])
        stats[key]['orders']             = number_to_currency(stats[key]['orders'])
        stats[key]['payouts']            = number_to_currency(stats[key]['payouts'])
        stats[key]['linkshare_est']      = number_to_currency(stats[key]['linkshare_est'])
        stats[key]['ads_est']            = number_to_currency(stats[key]['ads_est'])
        stats[key]['revenue']            = number_to_currency(stats[key]['revenue'])
        stats[key]['net_revenue']        = number_to_currency(stats[key]['net_revenue'])
        stats[key]['margin']             = number_with_precision(stats[key]['margin'], :precision => 2) + '%'
      end
    end

    stats
  end

end
