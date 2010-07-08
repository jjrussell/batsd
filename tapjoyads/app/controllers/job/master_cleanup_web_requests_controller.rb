class Job::MasterCleanupWebRequestsController < Job::JobController
  def index
    # Cleanup 2 days ago. Also retry cleanups for previous days, in case previous cleanups failed.
    # Attempting to cleanup a domain that has already been erased and backed up
    # doesn't have any adverse affects.
    day = Time.now.utc - 2.days
    
    3.times do
      date_string = day.iso8601[0,10]
      Sqs.send_message(QueueNames::CLEANUP_WEB_REQUESTS, date_string)
      day = day - 7.days
    end
    
    render :text => 'ok'
  end
end