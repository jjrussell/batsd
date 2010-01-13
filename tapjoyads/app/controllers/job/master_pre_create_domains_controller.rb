# Creates domains that will be used tomorrow

class Job::MasterPreCreateDomainsController < Job::JobController
  def index
    
    msg = (Time.now.utc + 1.day).iso8601[0,10]
    
    SqsGen2.new.queue(QueueNames::PRE_CREATE_DOMAINS).send_message(msg)
    render :text => "ok"
  end
end