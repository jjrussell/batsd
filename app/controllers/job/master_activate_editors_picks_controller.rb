class Job::MasterActivateEditorsPicksController < Job::JobController

  def index
    EditorsPick.to_activate.each do |pick|
      log_activity(pick)
      pick.activate!
      save_activity_logs
    end

    render :text => 'OK'
  end

end
