class Job::MasterUpdateRiskProfilesController < Job::JobController
  def index
    RiskProfile.update_offsets
    render :text => 'ok'
  end
end
