class Job::MasterVerificationsController < Job::JobController
  include SqsHelper
  
  def index
    send_to_sqs(QueueNames::VERIFICATIONS, 'run')
    
    render :text => 'ok'
  end
end
