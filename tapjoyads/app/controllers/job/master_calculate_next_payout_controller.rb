class Job::MasterCalculateNextPayoutController < Job::JobController
  after_filter :save_activity_logs, :only => [:index]

  def index
    Partner.to_calculate_next_payout_amount.each do |partner|

      partner.next_payout_amount = Partner.calculate_next_payout_amount(partner.id)
      if partner.payout_threshold_confirmation && partner.next_payout_amount >= partner.payout_threshold
        log_activity(partner)
        partner.payout_threshold_confirmation = false
      end
      partner.save!
    end

    render :text => 'ok'
  end

end
