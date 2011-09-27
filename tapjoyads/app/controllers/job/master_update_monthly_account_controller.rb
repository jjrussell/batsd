class Job::MasterUpdateMonthlyAccountController < Job::JobController
  def index
    now = Time.zone.now
    
    if MonthlyAccounting.count < MonthlyAccounting.expected_count
      Partner.find_each(:conditions => ["created_at < ?", now.beginning_of_month]) do |partner|
        next if partner.monthly_accountings.find_by_month_and_year(now.prev_month.month, now.prev_month.year).present?
      
        message = { :partner_id => partner.id, :month => now.last_month.month, :year => now.last_month.year }.to_json
        Sqs.send_message(QueueNames::UPDATE_MONTHLY_ACCOUNT, message)
        sleep(3)
      end
    end
    
    render :text => 'ok'
  end
end
