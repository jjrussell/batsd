class Job::MasterCalculateNextPayoutController < Job::JobController

  def index
    Partner.to_calculate_next_payout_amount.each do |partner|
      partner.next_payout_amount = Partner.calculate_next_payout_amount(partner.id)
      partner.save!
    end

    render :text => 'ok'
  end

end
