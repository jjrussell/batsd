class Job::MasterReloadMoneyController < Job::JobController

  def index
    now = Time.zone.now

    total_balance, total_pending_earnings = nil
    Partner.using_slave_db do
      total_balance          = Partner.sum(:balance, :conditions => "id != '#{TAPJOY_PARTNER_ID}'") / 100.0
      total_pending_earnings = Partner.sum(:pending_earnings, :conditions => "id != '#{TAPJOY_PARTNER_ID}'") / 100.0
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
    accounting_cutoff = Conversion.accounting_cutoff_time
    stats = {}

    Conversion.using_slave_db do
      start_times.each do |key, start_time|
        stats[key] = {}

        if start_time < accounting_cutoff
          stats[key]['advertiser_spend'] = MonthlyAccounting.since(start_time).prior_to(accounting_cutoff).sum(:spend)
          stats[key]['advertiser_spend'] += Conversion.created_between(accounting_cutoff, end_time).sum(:advertiser_amount)

          stats[key]['publisher_earnings'] = MonthlyAccounting.since(start_time).prior_to(accounting_cutoff).sum(:earnings, :conditions => ["partner_id != ?", TAPJOY_PARTNER_ID])
          stats[key]['publisher_earnings'] += Conversion.created_between(accounting_cutoff, end_time).sum(:publisher_amount, :conditions => ["publisher_partner_id != ?", TAPJOY_PARTNER_ID])
        else
          stats[key]['conversions']        = Conversion.created_between(start_time, end_time).count(:conditions => ["reward_type < 1000 OR reward_type >= 2000"])
          stats[key]['advertiser_spend']   = Conversion.created_between(start_time, end_time).sum(:advertiser_amount)
          stats[key]['publisher_earnings'] = Conversion.created_between(start_time, end_time).sum(:publisher_amount, :conditions => ["publisher_partner_id != ?", TAPJOY_PARTNER_ID])
        end

        stats[key]['advertiser_spend']   /= -100.0
        stats[key]['publisher_earnings'] /=  100.0

        stats[key]['marketing_credits'] = Order.created_between(start_time, end_time).sum(:amount, :conditions => "payment_method = 2 or payment_method = 4") / 100.0
        stats[key]['orders']            = Order.created_between(start_time, end_time).sum(:amount, :conditions => "payment_method != 2 and payment_method != 4") / 100.0
        stats[key]['payouts']           = Payout.created_between(start_time, end_time).sum(:amount) / 100.0
        stats[key]['linkshare_est']     = stats[key]['advertiser_spend'] * 0.026
        stats[key]['ads_est']           = 0.0
        stats[key]['revenue']           = stats[key]['advertiser_spend'] - stats[key]['marketing_credits'] + stats[key]['linkshare_est'] + stats[key]['ads_est']
        stats[key]['net_revenue']       = stats[key]['revenue'] - stats[key]['publisher_earnings']
        stats[key]['margin']            = stats[key]['net_revenue'] / stats[key]['revenue'] * 100
        stats[key]['avg_deduct_pct']    = (1 - SpendShare.over_range(start_time, end_time).average(:ratio)) * 100

        stats[key]['conversions']        = stats[key]['conversions'].nil? ? '-' : NumberHelper.number_with_delimiter(stats[key]['conversions'])
        stats[key]['advertiser_spend']   = NumberHelper.number_to_currency(stats[key]['advertiser_spend'])
        stats[key]['publisher_earnings'] = NumberHelper.number_to_currency(stats[key]['publisher_earnings'])
        stats[key]['marketing_credits']  = NumberHelper.number_to_currency(stats[key]['marketing_credits'])
        stats[key]['avg_deduct_pct']     = NumberHelper.number_to_percentage(stats[key]['avg_deduct_pct'], :precision => 2)
        stats[key]['orders']             = NumberHelper.number_to_currency(stats[key]['orders'])
        stats[key]['payouts']            = NumberHelper.number_to_currency(stats[key]['payouts'])
        stats[key]['linkshare_est']      = NumberHelper.number_to_currency(stats[key]['linkshare_est'])
        stats[key]['ads_est']            = NumberHelper.number_to_currency(stats[key]['ads_est'])
        stats[key]['revenue']            = NumberHelper.number_to_currency(stats[key]['revenue'])
        stats[key]['net_revenue']        = NumberHelper.number_to_currency(stats[key]['net_revenue'])
        stats[key]['margin']             = NumberHelper.number_to_percentage(stats[key]['margin'], :precision => 2)
      end
    end

    stats
  end

end
