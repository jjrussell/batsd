class Job::QueueUdidReportsController < Job::SqsReaderController

  before_filter :limit_concurrent_jobs, :only => :index

  def initialize
    super QueueNames::UDID_REPORTS
    @num_reads = 10
  end

  private

  def on_message(message)
    json = JSON.load(message.body)
    offer_id = json['offer_id']
    date_str = json['date']

    UdidReports.generate_report(offer_id, date_str)
  end

  def limit_concurrent_jobs
    if Dir.glob("#{RAILS_ROOT}/tmp/*.s3").length >= 12
      render :text => 'ok'
    end
  end

end
