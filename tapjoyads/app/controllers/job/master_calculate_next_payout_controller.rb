class Job::MasterCalculateNextPayoutController < Job::JobController
  include SqsHelper
  
  def index
    send_to_sqs(QueueNames::CALCULATE_NEXT_PAYOUT, 'run')
    
    render :text => 'ok'
  end
end