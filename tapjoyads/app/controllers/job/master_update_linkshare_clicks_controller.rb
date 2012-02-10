class Job::MasterUpdateLinkshareClicksController < Job::JobController

  def index
    LinksharePoller.poll
  end

end
