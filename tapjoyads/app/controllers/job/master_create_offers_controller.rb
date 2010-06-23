class Job::MasterCreateOffersController < Job::JobController
  include SqsHelper
  
  def index
    send_to_sqs(QueueNames::CREATE_OFFERS, 'run')
    
    render :text => 'ok'
  end
  
end