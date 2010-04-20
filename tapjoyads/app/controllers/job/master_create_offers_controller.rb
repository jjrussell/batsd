class Job::MasterCreateOffersController < Job::JobController
  include SqsHelper
  
  def index
    send_to_sqs(QueueNames::CREATE_OFFERS, 'run') if rand < 0.1
    send_to_sqs(QueueNames::CREATE_REWARDED_INSTALLS, 'run')
    
    render :text => 'ok'
  end
  
end