require 'csv'

class InvoiceReportGenerator
  # The implementation on the receiving end ignores these labels and relies on STABLE ORDERING
  #  Do not change the order of these columns without coordinating with DAZ Systems
  REPORT_COLUMNS = [
    'Legacy Invoice Number',
    'Line #',
    'STATUS',
    'Client ID',
    'TRX DATE (DD-MON-YYYY)',
    'Description',
    'Qty',
    'Unit Price',
    'email'
  ]

  attr_reader :date

  def initialize(date=Time.now.utc.to_date-1)
    @date = date
  end

  def generate_report
    CSV.open(filename_with_path, 'w', "\t") do |writer|
      writer << REPORT_COLUMNS

      invoices.each do |invoice|
        writer << rowify(invoice)
      end
      writer.close
    end
    filename_with_path
  end

  def invoices
    @invoices ||= Order.where(:updated_at => date_range, :payment_method => 1).includes(:partner)
  end

  def trx_date
    @trx_date ||= date.strftime("%d-%b-%Y")
  end

  def date_range
    t = Time.utc(date.year, date.month, date.day)
    (t..(t+1.day))
  end

  def filename
    @filename ||= "ORACLE_AR_INTERFACE_#{date.strftime('%m%d%Y')}.csv"
  end
 
  def filename_with_path
    @filename_with_path ||= "tmp/#{filename}"
  end

  # The implementation on the receiving end ignores column labels and relies on STABLE ORDERING
  #  Do not change the order of these columns without coordinating with DAZ Systems
  def rowify(invoice)
    [
      invoice.id,                                   # Legacy Invoice Number
      1,                                            # Line #
      'New',                                        # STATUS
      invoice.partner.client_id || 'none',          # Client ID
      trx_date,                                     # TRX DATE (DD-MON-YYYY)
      invoice.note_to_client || 'TapjoyAdsCredit',  # Description
      invoice.amount / 100.0,                       # Qty
      1,                                            # Unit Price
      invoice.billing_email                         # email
    ]
  end
end
