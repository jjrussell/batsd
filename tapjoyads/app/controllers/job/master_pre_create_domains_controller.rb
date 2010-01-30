# Creates domains that will be used tomorrow

class Job::MasterPreCreateDomainsController < Job::JobController
  include SqsHelper
  
  def index
    msg = (Time.now.utc + 1.day).iso8601[0,10]
    
    send_to_sqs(QueueNames::PRE_CREATE_DOMAINS, msg)
    render :text => "ok"
  end
end