class Job::MasterCalculateNextPayoutController < Job::JobController
  def index
    Partner.to_calculate_next_payout_amount.each do |partner|
      partner.calculate_next_payout_amount(true)
      sleep(10)
    end
    
    render :text => 'ok'
  end
end
