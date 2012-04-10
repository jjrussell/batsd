class Job::MasterCalculateNextPayoutController < Job::JobController

  def index
    Partner.to_calculate_next_payout_amount.each do |partner|
      partner.next_payout_amount = Partner.calculate_next_payout_amount(partner.id)
      if partner.payout_threshold_confirmation.confirmed && partner.next_payout_amount >= partner.payout_threshold
        partner.payout_threshold_confirmation.unconfirm
      end
      partner.save!
    end

    render :text => 'ok'
  end

end
