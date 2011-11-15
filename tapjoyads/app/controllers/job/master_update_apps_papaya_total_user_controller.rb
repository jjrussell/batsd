class Job::MasterUpdateAppsPapayaTotalUserController < Job::JobController
  def index
    Papaya.update_apps
    render :text => 'ok'
  end
end
