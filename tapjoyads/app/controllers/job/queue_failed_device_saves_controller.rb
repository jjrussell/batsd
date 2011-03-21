class Job::QueueFailedDeviceSavesController < Job::QueueFailedSdbSavesController
  
  def initialize
    super QueueNames::FAILED_DEVICE_SAVES
    @bucket = S3.bucket(BucketNames::FAILED_DEVICE_SAVES)
  end

private
  
  def should_save_sdb_item?(queued_sdb_item)
    true
  end
  
end
