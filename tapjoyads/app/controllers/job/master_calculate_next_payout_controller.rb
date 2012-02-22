class Job::MasterCalculateNextPayoutController < Job::JobController

  def index
    Partner.to_calculate_next_payout_amount.each do |partner|
      partner.next_payout_amount = Partner.calculate_next_payout_amount(partner.id)
      if partner.next_payout_amount >= 50_000_00
        partner.confirmed_for_payout = false
        partner.payout_confirmation_notes = 'SYSTEM: Payout is greater than or equal to $50,000.00'
      end
      partner.save!
    end

    render :text => 'ok'
  end

end
