class Job::MasterCreateOffersController < Job::JobController
  include RightAws
  
  def index
    SqsGen2.new.queue(QueueNames::CREATE_OFFERS).send_message('run')
    SqsGen2.new.queue(QueueNames::CREATE_REWARDED_INSTALLS).send_message('run')
    
    render :text => 'ok'
  end
  
end