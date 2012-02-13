class Job::MasterUpdateLinkshareClicksController < Job::JobController

  def index
    LinksharePoller.poll
    render :text => "ok"
  end

end
