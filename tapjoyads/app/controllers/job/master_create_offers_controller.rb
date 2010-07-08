class Job::MasterCreateOffersController < Job::JobController
  def index
    Sqs.send_message(QueueNames::CREATE_OFFERS, 'run')
    
    render :text => 'ok'
  end
  
end