class Job::MasterUpdateMonthlyAccountController < Job::JobController
  def index

    Partner.find_each do |partner|
      now = Time.zone.now
      json = {}
      json['partner_id'] = partner.id
      json['month'] = now.month
      json['year'] = now.year
      message = json.to_json
      Sqs.send_message(QueueNames::UPDATE_MONTHLY_ACCOUNT, message)
      sleep(1) #don't want to overwhelm the job servers
    end
    
    render :text => 'ok'
  end
end
