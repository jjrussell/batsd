class Job::MasterCleanupWebRequestsController < Job::JobController
  include SqsHelper
  
  def index
    # Cleanup 2 days ago. Also cleanup through 7 days prior, in case any previous cleanups failed.
    # Attempting to cleanup a domain that has already been erased and backed up
    # doesn't have any adverse affects.
    day = Time.now.utc - 2.days
    
    7.times do
      date_string = day.iso8601[0,10]
      send_to_sqs(QueueNames::CLEANUP_WEB_REQUESTS, date_string)
      day = day - 1.days
    end
    
    render :text => 'ok'
  end
end