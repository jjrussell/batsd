module Offer::ShowRateAlgorithms

  EVEN_DISTRIBUTION_SHOW_RATE_ALGO_ID = 0
  DELIVERY_ASAP_SHOW_RATE_ALGO_ID = 237

  attr_accessor :recent_clicks, :recent_installs
  attr_accessor :calculated_conversion_rate, :calculated_min_conversion_rate, :cvr_timeframe

  # calculate conversion rate based on timeframe
  def calculate_conversion_rate!(log_info=true)
    @recent_clicks, @recent_installs = nil, nil
    @calculated_conversion_rate, @calculated_min_conversion_rate, @cvr_timeframe = nil, nil, nil

    partner_balance   = self.partner.balance
    self.low_balance = partner_balance < 50000

    Rails.logger.info "Calculating new show_rate for offer #{self.name} (#{self.id})" if log_info

    old_show_rate = self.show_rate

    now = Time.zone.now
    show_rate_timeframe = self.is_free? ? 1.hour : 1.day
    start_time = now.beginning_of_hour - show_rate_timeframe
    stat_types = %w(paid_clicks paid_installs jailbroken_installs)
    appstats = Appstats.new(self.id, :start_time => start_time, :end_time => now, :stat_types => stat_types)
    @cvr_timeframe = appstats.end_time - appstats.start_time

    @recent_clicks = appstats.stats['paid_clicks'].sum.to_f
    @recent_installs = appstats.stats['paid_installs'].sum.to_f + appstats.stats['jailbroken_installs'].sum.to_f

    if @recent_clicks == 0
      @calculated_conversion_rate = (self.is_paid? ? 0.3 : 0.75)
    else
      @calculated_conversion_rate = @recent_installs / @recent_clicks
    end

    @calculated_conversion_rate = 1.0 if @calculated_conversion_rate > 1.0

    if log_info
      Rails.logger.info "Recent clicks: #{@recent_clicks}"
      Rails.logger.info "Recent installs: #{@recent_installs}"
      Rails.logger.info "cvr: #{@calculated_conversion_rate}"
    end

    @calculated_conversion_rate
  end

  def calculate_min_conversion_rate!
    @calculated_min_conversion_rate = calculate_min_conversion_rate
  end

  def has_low_conversion_rate?
    unless (@recent_clicks.present? and @calculated_conversion_rate.present? and @calculated_min_conversion_rate.present?)
      raise "Required attributes are not calculated yet"
    end

    @recent_clicks > 200 && @calculated_conversion_rate < @calculated_min_conversion_rate
  end

  def calculate_show_rate(algorithm_id=EVEN_DISTRIBUTION_SHOW_RATE_ALGO_ID, optimization_info={}, log_info=true)
    send("calcuate_show_rate_#{algorithm_id}", optimization_info, log_info)
  end

  def calculate_default_show_rate(log_info)
    send("calculate_show_rate_#{EVEN_DISTRIBUTION_SHOW_RATE_ALGO_ID}", optimization_info, log_info)
  end


  #----------------------------------------------------------------
  # Different show rate algorithms
  #----------------------------------------------------------------
  def required_optimization_info(algorithm_id, offer_hash)
    # This should probably be class method, but included in this file to centralize all show_rate related methods
    case algorithm_id
      when Offer::EVEN_DISTRIBUTION_SHOW_RATE_ALGO_ID
        optimization_info = {}
      when Offer::DELIVERY_ASAP_SHOW_RATE_ALGO_ID
        optimization_info = {:show_rate_new => offer_hash[:show_rate_new]}
      else
        optimization_info = {}
    end
    optimization_info
  end

  def calculate_show_rate_237(optimization_info={}, log_info=true)
    new_show_rate = optimization_info[:show_rate_new]
    return calculate_default_show_rate(optimization_info, log_info) unless new_show_rate.present?

    use_even_distribution = optimization_info[:even_distribution_show_rate]  # if ever an offer has the choice to choose show rate algorithm

    if new_show_rate > 0 and !use_even_distribution
      ret_show_rate = new_show_rate
    else
      ret_show_rate = calculate_default_show_rate(optimization_info, log_info)
    end

    ret_show_rate
  end

  def calcuate_show_rate_0(optimization_info={}, log_info=true)
    unless @recent_clicks.present? and @cvr_timeframe.present? and @calculated_conversion_rate.present?
      raise "Required attributes are not calculated yet"
    end

    old_show_rate = self.show_rate

    possible_clicks_per_second = @recent_clicks / @cvr_timeframe / old_show_rate

    # Assume a higher click/second rate than reality. This helps ensure that budgets come in slightly
    # under, rather than slightly over.
    possible_clicks_per_second = 1.1 * possible_clicks_per_second

    if log_info
      Rails.logger.info "Old show_rate: #{old_show_rate}"
      Rails.logger.info "Possible clicks per second: #{possible_clicks_per_second}"
    end

    unless self.low_balance?
      possible_installs_per_second = possible_clicks_per_second * @calculated_conversion_rate * old_show_rate
      potential_spend              = possible_installs_per_second * 48.hours * self.payment
      self.low_balance             = potential_spend > self.partner_balance
    end

    #end_of_day = Time.parse('00:00 CST', now + 18.hours).utc   # old way to find end of day
    #start_of_day = end_of_day - 1.day

    start_of_day = Time.parse('00:00 UTC').utc
    end_of_day = start_of_day + 24.hours

    stat_types = %w(paid_installs)
    appstats = Appstats.new(self.id, :start_time => start_of_day, :end_time => end_of_day, :stat_types => stat_types)
    num_installs_today = appstats.stats['paid_installs'].sum

    target_installs = self.calculate_target_installs(num_installs_today)
    target_clicks = target_installs / @calculated_conversion_rate

    if log_info
      Rails.logger.info "Daily budget: #{self.daily_budget}"
      Rails.logger.info "Target installs for remainder of day: #{target_installs}"
      Rails.logger.info "Target clicks for remainder of day: #{target_clicks}"
    end

    if target_clicks <= 0
      new_show_rate = 0
    else
      seconds_left_in_day = end_of_day - now
      Rails.logger.info "Seconds left in day: #{seconds_left_in_day}" if log_info
      new_show_rate = target_clicks / (possible_clicks_per_second * seconds_left_in_day)
      new_show_rate = 1 if new_show_rate > 1
    end

    if old_show_rate == 0 && target_installs > 0
      Rails.logger.info "Setting new show rate to 0.01, since old show rate was 0." if log_info
      new_show_rate = 0.01
    end

    # For low budget apps, don't just change to the new show_rate if it is larger than the old show_rate.
    # Instead, just add 2%. This prevents a period of 20 minutes with no clicks from causing the
    # show_rate to jump to 100% on the next run.
    if self.low_daily_budget? and (new_show_rate > old_show_rate)
      new_show_rate = [new_show_rate, old_show_rate + 0.02].min
    end

    if self.over_daily_budget?(num_installs_today)
      Rails.logger.info "Pushed too many installs. Overriding any calculations and setting show rate to 0." if log_info
      new_show_rate = 0
    end

    if self.has_overall_budget?
      start_time = Time.zone.parse('2010-01-01')
      stat_types = %w(paid_installs)
      appstats_overall = Appstats.new(self.id, :start_time => start_time, :end_time => now, :stat_types => stat_types)
      total_installs = appstats_overall.stats['paid_installs'].sum
      if total_installs > self.overall_budget
        Rails.logger.info "App over overall_budget. Overriding any calculations and setting show rate to 0." if log_info
        new_show_rate = 0
      end
    end

    if new_show_rate.to_f.nan?
      Rails.logger.info "Adjusted show_rate to 0.0 because it was NaN" if log_info
      new_show_rate = 0
    end

    Rails.logger.info "New show_rate: #{new_show_rate}"
    new_show_rate
  end

end
