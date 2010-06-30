class Job::MasterUpdateMonthlyAccountController < Job::JobController
  include SqsHelper
  
  def index

    Partner.all.each do |partner|
      now = Time.now.utc
      json = {}
      json['partner_id'] = partner.id
      json['month'] = now.month
      json['year'] = now.year
      message = json.to_json
      send_to_sqs(QueueNames::UPDATE_MONTHLY_ACCOUNT, message)
      sleep(10) #don't want to overwhelm the job servers
    end
    
    render :text => 'ok'
  end
end