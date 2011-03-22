class Job::QueueFailedSdbSavesController < Job::SqsReaderController
  
  def initialize(queue_name = QueueNames::FAILED_SDB_SAVES)
    super queue_name
    @bucket = S3.bucket(BucketNames::FAILED_SDB_SAVES)
  end
  
private
  
  def on_message(message)
    json             = JSON.parse(message.to_s)
    uuid             = json['uuid']
    @options         = json['options'].symbolize_keys
    @incomplete_path = "incomplete/#{uuid}"
    @complete_path   = "complete/#{uuid}"
    @skipped_path    = "skipped/#{uuid}"
    
    if @bucket.key(@incomplete_path).exists?
      save_to_sdb
    elsif @bucket.key(@complete_path).exists?
      Rails.logger.info("Already operated on #{uuid}")
    elsif @bucket.key(@skipped_path).exists?
      Rails.logger.info("Already skipped #{uuid}")
    else
      raise SdbObjectNotInS3.new("Serialized SDB object not found in S3. Need to retry saving #{uuid}.")
    end
  end
  
  def save_to_sdb
    sdb_string = @bucket.get(@incomplete_path)
    
    queued_sdb_item = SimpledbResource.deserialize(sdb_string)
    
    if should_save_sdb_item?(queued_sdb_item)
      queued_sdb_item.serial_save(@options.merge({ :catch_exceptions => false, :from_queue => true }))
      @bucket.move_key(@incomplete_path, @complete_path)
    else
      mc_key = "failed_sdb_saves.skipped.#{queued_sdb_item.this_domain_name}.#{(Time.zone.now.to_f / 1.hour).to_i}"
      Mc.increment_count(mc_key)
      @bucket.move_key(@incomplete_path, @skipped_path)
    end
  end
  
  def should_save_sdb_item?(queued_sdb_item)
    return true
    
    sdb_item = SimpledbResource.new(:key => queued_sdb_item.key, :domain_name => queued_sdb_item.this_domain_name, :load_from_memcache => false, :consistent => true)
    sdb_item.new_record? || queued_sdb_item.updated_at > sdb_item.updated_at
  end
  
end
