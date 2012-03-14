class Job::QueueFailedSdbSavesController < Job::SqsReaderController

  def initialize
    super QueueNames::FAILED_SDB_SAVES
    @bucket = S3.bucket(BucketNames::FAILED_SDB_SAVES)
  end

  private

  def on_message(message)
    json             = JSON.parse(message.body)
    uuid             = json['uuid']
    @options         = json['options'].symbolize_keys
    @incomplete_path = "incomplete/#{uuid}"
    @complete_path   = "complete/#{uuid}"
    @num_attrs_path  = "too_many_attributes/#{uuid}"

    if @bucket.objects[@incomplete_path].exists?
      save_to_sdb
    elsif @bucket.objects[@complete_path].exists? || @bucket.objects[@num_attrs_path].exists?
      Rails.logger.info("Already operated on #{uuid}")
    else
      raise SdbObjectNotInS3.new("Serialized SDB object not found in S3. Need to retry saving #{uuid}.")
    end
  end

  def save_to_sdb
    obj = @bucket.objects[@incomplete_path]
    queued_sdb_item = SimpledbResource.deserialize(obj.read)
    begin
      queued_sdb_item.save!(@options.merge({ :from_queue => true }))
    rescue RightAws::AwsError => e
      if e.message =~ /NumberSubmittedAttributesExceeded/
        obj.copy_to(@num_attrs_path)
      else
        raise e
      end
    else
      obj.copy_to(@complete_path)
    end
    obj.delete
  end

end
