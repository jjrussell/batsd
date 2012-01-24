#Papaya.update_device_by_date(Date.yesterday)
class Job::MasterUpdatePapayanDeviceController < Job::JobController

  def index
    Papaya.queue_daily_jobs

    render :text => 'ok'
  end

end
