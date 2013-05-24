class Job::MasterVerificationsController < Job::JobController
  attr_accessor :balance_mismatches, :earnings_mismatches

  def index
    check_conversion_partitions
    check_partner_balances

    render :text => 'ok'
  end

  def balance_mismatches
    @balance_mismatches ||= []
  end

  def earnings_mismatches
    @earnings_mismatches ||= []
  end

  private

  def check_conversion_partitions
    target_cutoff_time = Time.zone.now.beginning_of_month.next_month.next_month
    unless Conversion.get_partitions.any? { |partition| partition['CUTOFF_TIME'] == target_cutoff_time }
      Conversion.add_partition(target_cutoff_time)
    end
  end

  def check_partner_balances
    Partner.find_each do |partner|
      check_mismatch(partner.id) if check_today?(partner)
    end

    send_notification
  end

  def check_today?(partner)
    partner.id.hash % 7 == day_of_week
  end

  def day_of_week
    @day_of_week ||= Date.today.wday
  end

  def check_mismatch(partner_id)
    partner = Partner.verify_balances(partner_id)
    if partner.balance_changed?
      self.balance_mismatches  << {:id => partner.id, :before => partner.balance_was, :after => partner.balance}
    end
    if partner.pending_earnings_changed?
      self.earnings_mismatches << {:id => partner.id, :before => partner.pending_earnings_was, :after => partner.pending_earnings}
    end
  end

  def send_notification
    if self.balance_mismatches.any? || self.earnings_mismatches.any?
      TapjoyMailer.deliver_partner_money_mismatch(balance_mismatches, earnings_mismatches)
    end
  end
end
