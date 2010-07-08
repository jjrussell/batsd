class Job::MasterCalculateNextPayoutController < Job::JobController
  def index
    Sqs.send_message(QueueNames::CALCULATE_NEXT_PAYOUT, 'run')
    
    render :text => 'ok'
  end
end