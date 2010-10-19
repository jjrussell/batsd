class Job::MasterCleanupWebRequestsController < Job::JobController
  
  def index
    # Cleanup 2 days ago. Also retry cleanups for previous days, in case previous cleanups failed.
    # Attempting to cleanup a domain that has already been erased and backed up
    # doesn't have any adverse affects.
    day = Date.today - 2.days
    backup_options = { :delete_domain => true }
    
    2.times do
      MAX_WEB_REQUEST_DOMAINS.times do |num|
        domain_name = "web-request-#{day.to_s}-#{num}"
        message = { :domain_name => domain_name, :s3_bucket => BucketNames::WEB_REQUESTS, :backup_options => backup_options }.to_json
        Sqs.send_message(QueueNames::SDB_BACKUPS, message)
      end
      day -= 7.days
    end
    
    render :text => 'ok'
  end
  
end
