class Job::MasterCalculateNextPayoutController < Job::JobController

  def index
    Partner.to_calculate_next_payout_amount.each do |partner|
      partner.next_payout_amount = Partner.calculate_next_payout_amount(partner.id)
      if partner.payout_threshold_confirmation.confirmed == true && partner.next_payout_amount >= partner.payout_threshold
        partner.payout_threshold_confirmation.confirmed = false
        partner.payout_confirmation_notes = "SYSTEM: Payout is greater than or equal to #{NumberHelper.number_to_currency((partner.payout_threshold/100).to_f)}"
      end
      partner.save!
    end

    render :text => 'ok'
  end

end
