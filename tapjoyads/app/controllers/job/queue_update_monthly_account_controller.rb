class Job::QueueUpdateMonthlyAccountController < Job::SqsReaderController

  def initialize
    super QueueNames::UPDATE_MONTHLY_ACCOUNT
    @num_reads = 10
  end

  private

  def on_message(message)
    json = JSON.parse(message.body)

    partner = Partner.find(json['partner_id'])
    month = json['month']
    year = json['year']

    return if partner.monthly_accountings.find_by_month_and_year(month, year).present?

    monthly_accounting = MonthlyAccounting.new(:partner => partner, :month => month, :year => year)
    monthly_accounting.calculate_totals!
  end

end
