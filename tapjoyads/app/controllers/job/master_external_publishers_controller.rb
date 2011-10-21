class Job::MasterExternalPublishersController < Job::JobController
  def cache
    ExternalPublisher.cache
    render :text => "ok"
  end
  
  def populate_potential
    ExternalPublisher.populate_potential
    render :text => "ok"
  end
end
