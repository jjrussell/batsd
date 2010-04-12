class SdbBackup
  ##
  # Backs up the specified domain to s3.
  # Each line of the file represents a single item. The contents of the line are 
  # determined by calling SimpledbResource.serialize.
  # The file is then gzipped using the system `gzip` command.
  # Finally, the gzipped file is uploaded to s3.
  #
  # domain_name: The name of the domain to back up.
  # s3_bucket: The name of the s3 bucket to back up to.
  # options:
  #    where: The where clause for the sdb query - determines which items to actually back up.
  #    delete_rows: If true, the rows will be deleted after backing up.
  #    suffix: The suffix of the filename when saving to s3.
  def self.backup_domain(domain_name, s3_bucket, options = {})
    where = options.delete(:where)
    delete_rows = options.delete(:delete_rows) { false }
    suffix = options.delete(:suffix) { '' }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    Rails.logger.info "Backing up domain: #{domain_name}"
    
    file_name = "tmp/#{RUN_MODE_PREFIX}#{domain_name}#{suffix}.sdb"
    gzip_file_name = "#{file_name}.gz"
    s3_name = "#{RUN_MODE_PREFIX}#{domain_name}#{suffix}.sdb"
    
    file = open(file_name, 'w')
  
    item_list = []
    count = 0
    response = SimpledbResource.select(:domain_name => domain_name, :where => where) do |item|
      count += 1
      file.write(item.serialize)
      file.write("\n")
      item_list << item
    end
    box_usage = response[:box_usage]
    
    file.close
  
    Rails.logger.info "Made #{count} select queries. Total box usage: #{box_usage}"
  
    `gzip -f #{file_name}`
    
    self.write_to_s3(s3_name, gzip_file_name, s3_bucket, 3)
    
    if delete_rows
      item_list.each do |item|
        item.delete_all
      end
    end
  rescue RightAws::AwsError => e
    logger.info "Error while trying to back up #{domain_name}: #{e}"
  ensure
    `rm #{file_name}`
    `rm #{gzip_file_name}`
  end
  
  def self.write_to_s3(s3_name, local_name, bucket_name, num_retries)
    bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + bucket_name)
    num_retries.times do
      begin
        bucket.put(s3_name, open(local_name))
        Rails.logger.info "Successfully stored #{local_name} to s3 as #{s3_name}."
        return
      rescue RightAws::AwsError => e
        Rails.logger.info "Failed attempt to store #{local_name} to s3. Error: #{e}"
      end
    end
    raise "Failed to save #{local_name} to s3."
  end
end