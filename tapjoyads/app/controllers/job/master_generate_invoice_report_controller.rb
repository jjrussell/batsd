require 'invoice_report_generator'

class Job::MasterGenerateInvoiceReportController < Job::JobController
  def index
    InvoiceReportGenerator.perform(Time.now.utc.beginning_of_day.to_date - 1)
    render :text => 'ok'
  end
end
