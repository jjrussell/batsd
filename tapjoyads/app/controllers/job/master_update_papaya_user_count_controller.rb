class Job::MasterUpdatePapayaUserCountController < Job::JobController
  def index
    Papaya.queue_daily_update_user_count_jobs
    render :text => 'ok'
  end
end
