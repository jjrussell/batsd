class Job::CleanupWebRequestsController < Job::SqsReaderController
  include RightAws
  include TimeLogHelper
  
  def initialize
    super QueueNames::CLEANUP_WEB_REQUESTS
    @s3 = S3.new
    @bucket = S3::Bucket.create(@s3, 'web-requests')
  end
  
  def backup_date
    date = params[:date]
    
    on_message(date)
    
    render :text => 'ok'
  end
  
  def recover_domain
    domain_name = params[:domain_name]
    file_name = "tmp/#{RUN_MODE_PREFIX}#{domain_name}.sdb"
    gzip_file_name = "#{file_name}.gz"
    s3_name = "#{RUN_MODE_PREFIX}#{domain_name}.sdb"
    
    gzip_file = open(gzip_file_name, 'w')
    @s3.interface.get(@bucket.full_name, s3_name) do |chunk|
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
    message.delete
    
    date_string = message.to_s
    
    MAX_WEB_REQUEST_DOMAINS.times do |num|
      archive_domain("web-request-#{date_string}-#{num}")
    end
  end
  
  ##
  # Backs up the specified domain name to s3.
  # If no errors have occur while backing up, the domain is deleted.
  def archive_domain(domain_name)
    SdbBackup.backup_domain(domain_name, 'web-requests')
    
    retries = 3
    begin
      response = SimpledbResource.delete_domain(domain_name)
    rescue AwsError => e
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