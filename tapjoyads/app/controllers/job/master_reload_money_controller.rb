class Job::MasterReloadMoneyController < Job::JobController
  include ActionView::Helpers::NumberHelper

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
    android_ids = App.by_platform('android').collect(&:id)
    ios_ids = App.by_platform('iphone').collect(&:id)
    tj_apps = App.by_partner_id(TAPJOY_PARTNER_ID).collect(&:id)

    Conversion.using_slave_db do
      start_times.each do |key, start_time|
        stats[key] = {}

        if key == '24_hours'
          conditions = "path = '[reward]' and source = 'tj_games' and time >= '#{(start_time - 1.hour).to_s(:db)}' and time < '#{(end_time - 1.hour).to_s(:db)}'"
          select = 'sum(advertiser_amount) as adv_amount, count(source), sum(publisher_amount) as pub_amount'
          results = VerticaCluster.query('analytics.actions', :select => select, :conditions => conditions).first
          stats[key]['tjgames_conversions'] = number_with_delimiter(results[:count])
          stats[key]['tjgames_adv_spend'] = number_to_currency(results[:adv_amount].to_i / -100.0)
          stats[key]['tjgames_pub_earnings'] = number_to_currency(results[:pub_amount].to_i / 100.0)
        else
          stats[key]['tjgames_conversions'] = '-'
          stats[key]['tjgames_adv_spend'] = '-'
          stats[key]['tjgames_pub_earnings'] = '-'
        end

        if start_time < accounting_cutoff
          stats[key]['advertiser_spend'] = MonthlyAccounting.since(start_time).prior_to(accounting_cutoff).sum(:spend)
          stats[key]['advertiser_spend'] += Conversion.created_between(accounting_cutoff, end_time).sum(:advertiser_amount)

          stats[key]['publisher_earnings'] = MonthlyAccounting.since(start_time).prior_to(accounting_cutoff).sum(:earnings, :conditions => ["partner_id != ?", TAPJOY_PARTNER_ID])
          stats[key]['publisher_earnings'] += Conversion.created_between(accounting_cutoff, end_time).sum(:publisher_amount, :conditions => ["publisher_partner_id != ?", TAPJOY_PARTNER_ID])

          stats[key]['android_conversions']  = '-'
          stats[key]['android_adv_spend']    = '-'
          stats[key]['android_pub_earnings'] = '-'
          stats[key]['ios_conversions']      = '-'
          stats[key]['ios_adv_spend']        = '-'
          stats[key]['ios_pub_earnings']     = '-'
        else
          stats[key]['conversions']        = Conversion.created_between(start_time, end_time).count(:conditions => ["reward_type < 1000 OR reward_type >= 2000"])
          stats[key]['advertiser_spend']   = Conversion.created_between(start_time, end_time).sum(:advertiser_amount)
          stats[key]['publisher_earnings'] = Conversion.created_between(start_time, end_time).sum(:publisher_amount, :conditions => ["publisher_partner_id != ?", TAPJOY_PARTNER_ID])

          # TODO: make these queries work again.  right now the include_pub_apps part is making the queries larger than max_allowed_packet size for mysql.
          # stats[key]['android_conversions']  = Conversion.created_between(start_time, end_time).non_display.include_pub_apps(android_ids).count
          # stats[key]['android_adv_spend']    = Conversion.created_between(start_time, end_time).include_pub_apps(android_ids).sum(:advertiser_amount) / -100.0
          # stats[key]['android_pub_earnings'] = Conversion.created_between(start_time, end_time).exclude_pub_apps(tj_apps).include_pub_apps(android_ids).sum(:publisher_amount) / 100.0
          # stats[key]['ios_conversions']      = Conversion.created_between(start_time, end_time).non_display.include_pub_apps(ios_ids).count
          # stats[key]['ios_adv_spend']        = Conversion.created_between(start_time, end_time).include_pub_apps(ios_ids).sum(:advertiser_amount) / -100.0
          # stats[key]['ios_pub_earnings']     = Conversion.created_between(start_time, end_time).exclude_pub_apps(tj_apps).include_pub_apps(ios_ids).sum(:publisher_amount) / 100.0

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
        stats[key]['avg_deduct_pct']    = (1 - SpendShare.over_range(start_time, end_time).average(:ratio)) * 100
        stats[key]['network_costs']     = NetworkCost.created_between(start_time, end_time).sum(:amount) / 100.0

        stats[key]['conversions']        = stats[key]['conversions'].nil? ? '-' : number_with_delimiter(stats[key]['conversions'])
        stats[key]['advertiser_spend']   = number_to_currency(stats[key]['advertiser_spend'])
        stats[key]['publisher_earnings'] = number_to_currency(stats[key]['publisher_earnings'])
        stats[key]['marketing_credits']  = number_to_currency(stats[key]['marketing_credits'])
        stats[key]['avg_deduct_pct']     = number_to_percentage(stats[key]['avg_deduct_pct'], :precision => 2)
        stats[key]['orders']             = number_to_currency(stats[key]['orders'])
        stats[key]['payouts']            = number_to_currency(stats[key]['payouts'])
        stats[key]['linkshare_est']      = number_to_currency(stats[key]['linkshare_est'])
        stats[key]['ads_est']            = number_to_currency(stats[key]['ads_est'])
        stats[key]['revenue']            = number_to_currency(stats[key]['revenue'])
        stats[key]['net_revenue']        = number_to_currency(stats[key]['net_revenue'])
        stats[key]['margin']             = number_to_percentage(stats[key]['margin'], :precision => 2)
        stats[key]['network_costs']      = number_to_currency(stats[key]['network_costs'])
      end
    end

    stats
  end

end
