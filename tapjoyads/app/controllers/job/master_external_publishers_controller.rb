class Job::MasterExternalPublishersController < Job::JobController
  def cache
    ExternalPublishers.cache
    render :text => "ok"
  end
  
  def populate_potential
    ExternalPublishers.populate_potential
    render :text => "ok"
  end
end