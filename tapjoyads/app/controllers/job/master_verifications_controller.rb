class Job::MasterVerificationsController < Job::JobController
  def index
    check_conversion_partitions
    check_partner_balances
    
    render :text => 'ok'
  end
  
private
  
  def check_conversion_partitions
    target_cutoff_time = Time.zone.now.beginning_of_month.next_month.next_month
    unless Conversion.get_partitions.any? { |partition| partition['CUTOFF_TIME'] == target_cutoff_time }
      Conversion.add_partition(target_cutoff_time)
    end
  end
  
  def check_partner_balances
    day_of_week = Date.today.wday
    
    Partner.find_each do |partner|
      next unless partner.id.hash % 7 == day_of_week
      
      Partner.verify_balances(partner.id, true)
    end
  end
  
end
