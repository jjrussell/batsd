class Job::MasterUpdateMonthlyAccountController < Job::JobController
  def index
    now = Time.zone.now
    
    if now.day == 1 || now.day == 15
      Partner.find_each do |partner|
        json = {}
        json['partner_id'] = partner.id
        json['month'] = now.month
        json['year'] = now.year
        message = json.to_json
        Sqs.send_message(QueueNames::UPDATE_MONTHLY_ACCOUNT, message)
        sleep(3) # don't want to overwhelm the job servers
      end
    end
    
    render :text => 'ok'
  end
end
