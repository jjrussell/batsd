class Job::MasterVerificationsController < Job::JobController
  def index
    check_partner_balances
    
    render :text => 'ok'
  end
  
private
  
  def check_partner_balances
    day_of_week = Date.today.wday
    
    Partner.find_each do |partner|
      next unless partner.id.hash % 7 == day_of_week
      
      partner.recalculate_balances(false, true)
      sleep(5)
    end
  end
  
end
