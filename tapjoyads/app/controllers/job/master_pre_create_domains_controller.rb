# Creates domains that will be used tomorrow

class Job::MasterPreCreateDomainsController < Job::JobController
  def index
    msg = (Time.now.utc + 1.day).iso8601[0,10]
    
    Sqs.send_message(QueueNames::PRE_CREATE_DOMAINS, msg)
    render :text => "ok"
  end
end