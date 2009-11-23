#

class Job::CleanupWebRequestsController < Job::JobController
  include RightAws
  
  def initialize
    @s3 = S3.new(ENV['AMAZON_ACCESS_KEY_ID'], ENV['AMAZON_SECRET_ACCESS_KEY'])
    @bucket = S3::Bucket.create(@s3, 'web-requests')
  end
  
  def index
    # Todo before this can be a real job: generate date automatically.
    date = params[:date]
    
    backup_domain("web-request-#{date}")
    MAX_WEB_REQUEST_DOMAINS.times do |num|
      backup_domain("web-request-#{date}-#{num}")
    end
    
    
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
  
  ##
  # Backs up the specified domain name to s3.
  # Each line of the file represents a single item. The contents of the line are 
  # determined by calling SimpledbResource.serialize.
  # The file is then gzipped using the system `gzip` command.
  # Next, the file is uploaded to s3, in to the 'web-requests' bucket.
  # Finally, assuming no errors have occurred, the domain is deleted.
  def backup_domain(domain_name)
    file_name = "tmp/#{RUN_MODE_PREFIX}#{domain_name}.sdb"
    gzip_file_name = "#{file_name}.gz"
    s3_name = "#{RUN_MODE_PREFIX}#{domain_name}.sdb"
    file = open(file_name, 'w')
    
    next_token = nil
    begin 
      response = SimpledbResource.select(domain_name, '*', nil, nil, next_token)
      puts response
      next_token = response[:next_token]
      response[:items].each do |item|
        file.write(item.serialize)
        file.write("\n")
      end
    end while next_token
    file.close
    
    `gzip -f #{file_name}`
    
    @bucket.put(s3_name, open(gzip_file_name))
    
    SimpledbResource.delete_domain(domain_name)
    `rm #{gzip_file_name}`
    
    logger.info "Successfully backed up #{domain_name}"
  rescue AwsError => e
    logger.info "Error while trying to back up #{domain_name}: #{e}"
  end
  
end