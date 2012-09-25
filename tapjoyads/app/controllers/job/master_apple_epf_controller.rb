class Job::MasterAppleEpfController < Job::JobController
  #TODO: write test to make sure EPF urls haven't changed.
  def index
    AppleEPF.process_full
    render :text => 'ok'
  end
end
