class Job::CleanupStoreCLickController < Job::SqsReaderController
  include RightAws
  include TimeLogHelper
  
  def initialize
    super QueueNames::CLEANUP_STORE_CLICKS
    @s3 = S3.new
    @bucket = S3::Bucket.create(@s3, 'store-clicks')
  end

  private
  
  def on_message(message)
    date_string = message.to_s
    backup_date(date_string)
  end

  ##
  # Backs up the specified domain name to s3.
  # Each line of the file represents a single item. The contents of the line are 
  # determined by calling SimpledbResource.serialize.
  # The file is then gzipped using the system `gzip` command.
  # Next, the file is uploaded to s3, in to the 'web-requests' bucket.
  # Finally, assuming no errors have occurred, the domain is deleted.
  def backup_date(date_string)
    start_time = Time.parse(date_string).beginning_of_day.to_i
    end_time = start_time + 24.hours
    
    
    Rails.logger.info "Backing up store-clicks on #{date_string}"
    file_name = "tmp/#{RUN_MODE_PREFIX}store-click_#{date_string}.sdb"
    gzip_file_name = "#{file_name}.gz"
    s3_name = "#{RUN_MODE_PREFIX}store-click_#{date_string}.sdb"
    
    time_log("Backing up store-clicks on #{date_string}") do
      file = open(file_name, 'w')
    
      count = 0
      response = SimpledbResource.select(:domain_name => 'store-click', 
          :where => "click_date >= '#{start_time}' and click_date < '#{end_time}'") do |item|
        count += 1
        file.write(item.serialize)
        file.write("\n")
        #item.delete_all
      end
      box_usage = response[:box_usage]
      
      file.close
    
      Rails.logger.info "Made #{count} select queries. Total box usage: #{box_usage}"
    
      `gzip -f #{file_name}`

      write_to_s3(s3_name, gzip_file_name, 3)
    end
    logger.info "Successfully backed up store-clicks for date: #{date_string}"
  rescue AwsError => e
    logger.info "Error while trying to back up store-clicks for date #{date_string}: #{e}"
  ensure
    `rm #{file_name}`
    `rm #{gzip_file_name}`
  end
  
  
  def write_to_s3(s3_name, local_name, num_retries)
    num_retries.times do
      begin
        @bucket.put(s3_name, open(local_name))
        Rails.logger.info "Successfully stored #{local_name} to s3 as #{s3_name}."
        return
      rescue AwsError => e
        Rails.logger.info "Failed attempt to store #{local_name} to s3. Error: #{e}"
      end
    end
    raise "Failed to save #{local_name} to s3."
  end

end