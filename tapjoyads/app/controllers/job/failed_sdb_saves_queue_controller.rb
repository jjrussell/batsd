class Job::FailedSdbSavesQueueController < Job::SqsReaderController
  
  def initialize
    super QueueNames::FAILED_SDB_SAVES
    @bucket = S3.bucket(BucketNames::FAILED_SDB_SAVES)
  end
  
private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    uuid = json['uuid']
    @options = json['options'].symbolize_keys
    @incomplete_path = "incomplete/#{uuid}"
    @complete_path = "complete/#{uuid}"
    
    if @bucket.key(@incomplete_path).exists?
      save_to_sdb
    elsif @bucket.key(@complete_path).exists?
      Rails.logger.info("Already operated on #{uuid}")
    else
      raise "Serialized SDB object not found in S3. Need to retry saving #{uuid}."
    end
  end
  
  def save_to_sdb
    sdb_string = @bucket.get(@incomplete_path)
    
    sdb_item = SimpledbResource.deserialize(sdb_string)
    sdb_item.put('from_queue', Time.zone.now.to_f.to_s)
    
    params[:domain_name] = sdb_item.this_domain_name
    
    sdb_item.serial_save(@options.merge({ :catch_exceptions => false }))
    
    @bucket.move_key(@incomplete_path, @complete_path)
  end
  
end
