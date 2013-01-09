require 'invoice_report_generator'

class Job::MasterGenerateInvoiceReportController < Job::JobController
  BUCKET = S3.bucket(BucketNames::INVOICE_REPORTS)

  def index
    yesterday = Time.now.utc.to_date - 1
    
    path = InvoiceReportGenerator.new(yesterday).generate_report
    begin
      upload_report(path)
    rescue Exception => e
      Notifier.alert_new_relic(e, "Failed to upload invoice report for #{yesterday}")
    ensure
      File.delete(path)
    end

    render :text => 'ok'
  end

  private
  
  def upload_report(path)
    BUCKET.objects[File.basename(path)].write(:data => File.open(path).read, :acl => :authenticated_read)
  end
end
