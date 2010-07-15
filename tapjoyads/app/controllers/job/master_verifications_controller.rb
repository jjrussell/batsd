class Job::MasterVerificationsController < Job::JobController
  def index
    check_partner_balances
    
    render :text => 'ok'
  end
  
private
  
  def check_partner_balances
    Partner.find_each do |partner|
      partner.recalculate_balances(false, true)
    end
  end
  
end
