class Job::MasterAlertsController < Job::JobController

  def index
    Alert.run_all

    render :text => 'ok'
  end

end
