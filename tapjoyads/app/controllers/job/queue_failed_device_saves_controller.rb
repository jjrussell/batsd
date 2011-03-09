class Job::QueueFailedDeviceSavesController < Job::QueueFailedSdbSavesController
  
  def initialize
    super QueueNames::FAILED_DEVICE_SAVES
    @bucket = S3.bucket(BucketNames::FAILED_DEVICE_SAVES)
  end
  
end
