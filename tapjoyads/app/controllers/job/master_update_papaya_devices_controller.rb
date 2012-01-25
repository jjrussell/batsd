class Job::MasterUpdatePapayaDevicesController < Job::JobController
  def index
    Papaya.queue_daily_device_jobs
    render :text => 'ok'
  end
end
