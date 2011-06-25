class Job::QueueCreateInvoicesController < Job::SqsReaderController

  def initialize
    super QueueNames::CREATE_INVOICES
  end

private

  def on_message(message)
    order = Order.find(message)
    order.create_freshbooks_invoice unless order.invoice_id
    order.save!
  end
end
