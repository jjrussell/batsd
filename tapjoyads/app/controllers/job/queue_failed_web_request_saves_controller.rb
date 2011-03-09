class Job::QueueFailedWebRequestSavesController < Job::QueueFailedSdbSavesController
  
  def initialize
    super QueueNames::FAILED_WEB_REQUEST_SAVES
    @bucket = S3.bucket(BucketNames::FAILED_WEB_REQUEST_SAVES)
  end
  
end
