class Job::MasterVerificationsController < Job::JobController
  def index
    Sqs.send_message(QueueNames::VERIFICATIONS, 'run')
    
    render :text => 'ok'
  end
end
