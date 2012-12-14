class Job::MasterExpireCurrencySalesController < Jobs::JobController
  def index
    CurrencySale.past.each do |sale|
      sale.currency.cache if sale.end_time > 2.hours.ago
    end
  end
end
