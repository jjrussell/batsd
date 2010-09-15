class Job::MasterUpdateMonthlyAccountController < Job::JobController
  def index
    now = Time.zone.now
    
    Partner.find_each do |partner|
      next unless partner.id.hash % 7 == now.wday
      
      json = {}
      json['partner_id'] = partner.id
      json['month'] = now.month
      json['year'] = now.year
      message = json.to_json
      Sqs.send_message(QueueNames::UPDATE_MONTHLY_ACCOUNT, message)
      sleep(10)
    end
    
    render :text => 'ok'
  end
end
