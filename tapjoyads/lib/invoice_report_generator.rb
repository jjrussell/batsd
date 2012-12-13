require 'csv'

class InvoiceReportGenerator
  BUCKET = S3.bucket(BucketNames::INVOICE_REPORTS)
  REPORT_COLUMNS = [
    'Legacy Invoice Number',
    'Line #',
    'STATUS',
    'Client ID',
    'TRX DATE (DD-MON-YYYY)',
    'Item Number',
    'Description',
    'Qty',
    'Unit Price',
    'email'
  ]
  attr_reader :date

  def self.perform(date)
    new(date).perform
  end

  def initialize(date)
    @date = date
  end

  def perform
    generate_report!
    upload_report!
    cleanup!
  end

  def filename
    @filename ||= "ORACLE_AR_INTERFACE_#{'%02d' % date.month}#{'%02d' % date.day}#{date.year}.csv"
  end

  def filename_with_path
    @filename_with_path ||= "tmp/#{filename}"
  end

  def generate_report!
    CSV.open(filename_with_path, 'w', "\t") do |writer|
      writer << REPORT_COLUMNS

      invoices.each do |invoice|
        writer << rowify(invoice)
      end
      writer.close
    end
  end

  def upload_report!
    BUCKET.objects[filename].write(:data => File.open(filename_with_path).read, :acl => :authenticated_read)
  end

  def cleanup!
    File.delete(filename_with_path)
  end

  def invoices
    @invoices ||= Order.where(:updated_at => (date..date+1), :payment_method => 1).includes(:partner)
  end

  private
  def rowify(invoice)
    [
      invoice.invoice_id,                  # Legacy Invoice Number
      1,                                   # Line #
      invoice.status_string,               # STATUS
      invoice.partner.client_id || 'none', # Client ID
      trx_date,                            # TRX DATE (DD-MON-YYYY)
      invoice.id,                          # Item Nummber
      invoice.description,                 # Description
      1,                                   # Qty
      invoice.amount,                      # Unit Price
      invoice.billing_email                # email
    ]
  end

  def trx_date
    @trx_date ||= "#{'%02d' % date.day}-#{'%02d' % date.month}-#{date.year}"
  end

  def date_range
    t = Time.utc(date.year, date.month, date.day)
    (t..(t+1.day))
  end
end
