class Job::MasterUdidReportsController < Job::JobController

  def index
    UdidReports.queue_daily_jobs

    render :text => 'ok'
  end

end
