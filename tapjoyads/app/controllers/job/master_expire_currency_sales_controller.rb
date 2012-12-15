class Job::MasterExpireCurrencySalesController < Job::JobController
  def index
    CurrencySale.past.each do |sale|
      sale.currency.cache if sale.end_time > 2.hours.ago
    end

    render :text => 'ok'
  end
end
