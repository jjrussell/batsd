class Job::QueueCreateInvoicesController < Job::SqsReaderController

  def initialize
    super QueueNames::CREATE_INVOICES
  end

  private

  def on_message(message)
    Order.transaction do
      order = Order.find(message.body, :lock => 'FOR UPDATE')
      order.create_freshbooks_invoice! unless (order.invoice_id || order.failed_invoice?)
    end
  end

end
