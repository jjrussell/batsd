class Job::QueueFailedSdbSavesController < Job::SqsReaderController

  def initialize
    super QueueNames::FAILED_SDB_SAVES
    @bucket = S3.bucket(BucketNames::FAILED_SDB_SAVES)
  end

  private

  def on_message(message)
    json             = JSON.parse(message.to_s)
    uuid             = json['uuid']
    @options         = json['options'].symbolize_keys
    @incomplete_path = "incomplete/#{uuid}"
    @complete_path   = "complete/#{uuid}"
    
    if @bucket.objects[@incomplete_path].exists?
      save_to_sdb
    elsif @bucket.objects[@complete_path].exists?
      Rails.logger.info("Already operated on #{uuid}")
    else
      raise SdbObjectNotInS3.new("Serialized SDB object not found in S3. Need to retry saving #{uuid}.")
    end
  end

  def save_to_sdb
    obj = @bucket.objects[@incomplete_path]
    queued_sdb_item = SimpledbResource.deserialize(obj.read)
    queued_sdb_item.serial_save(@options.merge({ :catch_exceptions => false, :from_queue => true }))
    obj.copy_to(@complete_path)
    obj.delete
  end

end
