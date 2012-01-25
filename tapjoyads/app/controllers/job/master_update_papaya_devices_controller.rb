class Job::MasterUpdatePapayaDevicesController < Job::JobController
  def index
    Papaya.queue_daily_update_devices_jobs
    render :text => 'ok'
  end
end
