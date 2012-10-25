class Job::MasterAppleEpfController < Job::JobController
  #TODO: write test to make sure EPF urls haven't changed.
  def index
    Date.today.wday == 4 ? AppleEPF.process_full : AppleEPF.process_incremental
    render :text => 'ok'
  end
end
