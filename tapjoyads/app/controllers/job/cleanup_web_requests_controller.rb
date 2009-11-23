#

class Job::CleanupWebRequestsController < Job::JobController
  include RightAws
  include TimeLogHelper
  
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
    
    time_log("Backed up domain: #{domain_name}") do
      file = open(file_name, 'w')
    
      box_usage = 0
      count = 0
      next_token = nil
      begin 
        count += 1
        response = SimpledbResource.select(domain_name, '*', nil, nil, next_token)
        puts response
        next_token = response[:next_token]
        box_usage += response[:box_usage].to_f
        response[:items].each do |item|
          file.write(item.serialize)
          file.write("\n")
        end
      end while next_token
      file.close
    
      Rails.logger.info "Made #{count} select queries. Total box usage: #{box_usage}"
    
      `gzip -f #{file_name}`

      @bucket.put(s3_name, open(gzip_file_name))
      Rails.logger.info "Successfully stored #{s3_name} to s3."
  
      reponse = SimpledbResource.delete_domain(domain_name)
      Rails.logger.info "Deleted domain. Box usage for delete: #{response[:box_usage]}"
    end
    logger.info "Successfully backed up #{domain_name}"
  rescue AwsError => e
    logger.info "Error while trying to back up #{domain_name}: #{e}"
  ensure
    `rm #{file_name}`
    `rm #{gzip_file_name}`
  end
  
end