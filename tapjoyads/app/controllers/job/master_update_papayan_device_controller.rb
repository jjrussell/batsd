class Job::MasterUpdatePapayanDeviceController < Job::JobController
  def index
    Papaya.update_device_by_date(Date.yesterday)
    render :text => 'ok'
  end
end
