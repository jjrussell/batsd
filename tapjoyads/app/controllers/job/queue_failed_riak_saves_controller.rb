class Job::QueueFailedRiakSavesController < Job::SqsReaderController

  def initialize
    super QueueNames::FAILED_RIAK_SAVES
    @bucket = S3.bucket(BucketNames::FAILED_RIAK_SAVES)
    @raise_on_error = false
  end

  private
  def on_message(message)
    json             = JSON.parse(message.body)
    uuid             = json['uuid']
    @incomplete_path = "incomplete/#{uuid}"
    @complete_path   = "complete/#{uuid}"

    if @bucket.objects[@incomplete_path].exists?
      save_to_riak
    elsif @bucket.objects[@complete_path].exists?
      Rails.logger.info("Already operated on #{uuid}")
    else
      raise RiakObjectNotInS3.new("Serialized Riak object not found in S3. Need to retry saving #{uuid}.")
    end
  end

  def save_to_riak
    s3_obj = @bucket.objects[@incomplete_path]
    riak_data = JSON.parse(s3_obj.read)
    retry_count = 0
    begin
      RiakWrapper.put(riak_data["bucket_name"], riak_data["key"], riak_data["json_data"] || {}, riak_data["indexes"] || [])
    rescue Exception => e
      retry_count += 1
      retry if retry_count < 4
      Rails.logger.error "Error writing to Riak in queue #{e.backtrace}"
      #Let's catch all Riak exceptions.  We don't want these to bubble up.  I'll fire
      #off an Airbrake message just so I know what's going on
      Airbrake.notify_or_ignore(e)
      #Re-raise the exception for later processing
      raise e
    else
      s3_obj.copy_to(@complete_path)
    end
    s3_obj.delete
  end
end