class Job::MasterUpdateRevShareController < Job::JobController
  def index
    Currency.find_each do |currency|
      currency.set_values_from_partner_and_reseller
      currency.save!
    end

    render :text => 'ok'
  end
end
