class Job::MasterUpdateAppsPapayaTotalUserController < Job::JobController
  def index
    Papaya.queue_daily_user_count_jobs
    render :text => 'ok'
  end
end
