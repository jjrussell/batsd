class Job::FailedSdbSavesQueueController < Job::SqsReaderController
  include NewRelicHelper
  
  def initialize
    super QueueNames::FAILED_SDB_SAVES
  end
  
  private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    
    s3 = RightAws::S3.new(nil, nil, :multi_thread => true)
    
    options = {}
    
    bucket = s3.bucket('failed-sdb-saves')
    
    begin
      sdb_string = bucket.get(json['uuid'])
    rescue RightAws::AwsError => e
      if e.message.starts_with?('NoSuchKey')
        # This will raise an error if the key is not found.
        bucket.get("complete/#{json['uuid']}")
        
        Rails.logger.info("Already operated on #{json['uuid']}")
        return
      else
        raise e
      end
    end
    
    string_options = json['options']
    
    # Convert all keys to symbols, rather than strings.
    string_options.each do |key, value|
      options[key.to_sym] = value
    end
    
    sdb_item = SimpledbResource.deserialize(sdb_string)
    sdb_item.put('from_queue', Time.now.utc.to_f.to_s)
    
    params[:domain_name] = sdb_item.this_domain_name
    
    if sdb_item.key == '0203fd6695c97278729481ff3e19fc381d7cd37a' and sdb_item.this_domain_name == 'device_app_list_8'
      bucket.move_key(json['uuid'], "complete/#{json['uuid']}")
    end
    
    sdb_item.serial_save(options.merge({:catch_exceptions => false}))
    
    bucket.move_key(json['uuid'], "complete/#{json['uuid']}")
  end
end