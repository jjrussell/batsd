class Job::MasterUpdateRevShareController < Job::JobController
  def index
    Mc.delete('currency.spend_share_ratio')
    Currency.find_each do |currency|
      currency.set_values_from_partner_and_reseller
      currency.save!
    end
    
    render :text => 'ok'
  end
end
