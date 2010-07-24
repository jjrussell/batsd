class Job::CleanupWebRequestsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::CLEANUP_WEB_REQUESTS
  end
  
  def backup_date
    date = params[:date]
    
    if date =~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/
      on_message(date)
      render :text => 'ok'
    else
      render :text => 'invalid date'
    end
  end
  
  def recover_domain
    domain_name = params[:domain_name]
    file_name = "tmp/#{RUN_MODE_PREFIX}#{domain_name}.sdb"
    gzip_file_name = "#{file_name}.gz"
    s3_name = "#{RUN_MODE_PREFIX}#{domain_name}.sdb"
    
    gzip_file = open(gzip_file_name, 'w')
    S3.s3.interface.get(BucketNames::WEB_REQUESTS, s3_name) do |chunk|
      gzip_file.write(chunk)
    end
    gzip_file.close
    
    `gunzip -f #{gzip_file_name}`
    
    SimpledbResource.create_domain(domain_name)
    
    file = open(file_name)
    items = []
    file.each do |line|
      items.push(SimpledbResource.deserialize(line))
      if items.length == 25
        SimpledbResource.put_items(items)
        items.clear
      end
    end
    SimpledbResource.put_items(items)
    
    `rm #{file_name}`
    
    render :text => 'ok'
  end
  
private
  
  def on_message(message)
    # Delete the message immediately. This is sure to take longer than 60 seconds.
    # If this fails, it will automatically be retried on later days.
    message.delete if message.is_a?(RightAws::SqsGen2::Message)
    
    date_string = message.to_s
    
    MAX_WEB_REQUEST_DOMAINS.times do |num|
      archive_domain("web-request-#{date_string}-#{num}")
    end
  end
  
  ##
  # Backs up the specified domain name to s3.
  # If no errors have occur while backing up, the domain is deleted.
  def archive_domain(domain_name)
    SdbBackup.backup_domain(domain_name, BucketNames::WEB_REQUESTS)
    
    retries = 3
    begin
      response = SimpledbResource.delete_domain(domain_name)
    rescue RightAws::AwsError => e
      sleep(1)
      if retries > 0
        retries -= 1
        retry
      else
        raise e
      end
    end
    
    Rails.logger.info "Deleted domain. Box usage for delete: #{response[:box_usage]}"
    
    logger.info "Successfully backed up #{domain_name}"
  end
end
