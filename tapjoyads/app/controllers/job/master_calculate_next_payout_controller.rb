class Job::MasterCalculateNextPayoutController < Job::JobController
  MAX_FAILURE_RATIO = 0.10

  after_filter :save_activity_logs, :only => [:index]

  def index
    partners = Partner.to_calculate_next_payout_amount
    failure_count = 0
    partners.each do |partner|
      begin
        partner.next_payout_amount = Partner.calculate_next_payout_amount(partner.id)
        if partner.payout_threshold_confirmation && partner.next_payout_amount >= partner.payout_threshold
          log_activity(partner)
          partner.payout_threshold_confirmation = false
        end
        partner.save!
      rescue => exception
        failure_count += 1
        Airbrake.notify(exception, airbrake_request_data)
        if failure_count.to_f / partners.count.to_f  > MAX_FAILURE_RATIO
          raise "Maximum tolerable failure count exceeded. Last failure: " + exception
        end
      end
    end

    render :text => 'ok'
  end

end
