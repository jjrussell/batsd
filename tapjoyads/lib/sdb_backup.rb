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
    job_start_time = Time.zone.now
    where          = options.delete(:where)
    delete_rows    = options.delete(:delete_rows)   { false }
    delete_domain  = options.delete(:delete_domain) { false }
    prefix         = options.delete(:prefix)        { '' }
    suffix         = options.delete(:suffix)        { '' }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    Rails.logger.info "Backing up domain: #{domain_name}"

    file_name = "tmp/#{RUN_MODE_PREFIX}#{domain_name}#{suffix}.sdb"
    gzip_file_name = "#{file_name}.gz"
    s3_name = "#{prefix}#{RUN_MODE_PREFIX}#{domain_name}#{suffix}.sdb.gz"

    file = open(file_name, 'w')

    key_list = []
    count = 0
    response = SimpledbResource.select(:domain_name => domain_name, :where => where, :retries => 100000) do |item|
      count += 1
      file.write(item.serialize)
      file.write("\n")
      key_list << item.key if delete_rows
    end
    box_usage = response[:box_usage]

    file.close

    Rails.logger.info "Made #{count} select queries. Total box usage: #{box_usage}. Retry count: #{response[:retry_count]}"

    `gzip -f #{file_name}`

    self.write_to_s3(s3_name, gzip_file_name, s3_bucket, 10)

    if delete_domain
      Rails.logger.info "Deleting domain"
      retries = 20
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
      Rails.logger.info "Deleted domain #{domain_name}"
    end

    if delete_rows
      Rails.logger.info "Deleting rows"
      key_list.each do |key|
        begin
          item = SimpledbResource.new(:key => key, :load => false, :domain_name => domain_name)
          item.delete_all(false)
        rescue RightAws::AwsError => e
          retry
        end
      end
      Rails.logger.info "Deleted #{key_list.length} rows."
    end
  ensure
    `rm #{file_name}`
    `rm #{gzip_file_name}`
  end

  def self.write_to_s3(s3_name, local_name, bucket_name, num_retries)
    bucket = S3.bucket(bucket_name)

    while bucket.objects[s3_name].exists?
      s3_name += '_2'
    end

    1.upto(num_retries) do |attempt_num|
      begin
        bucket.objects[s3_name].write(:file => local_name)
        Rails.logger.info "Successfully stored #{local_name} to s3 as #{s3_name} after #{attempt_num} attempts."
        return
      rescue AWS::Errors::Base => e
        Rails.logger.info "Failed attempt to store #{local_name} to s3. Error: #{e}"
      end
      sleep(attempt_num * 5)
    end
    raise "Failed to save #{local_name} to s3 after #{num_retries} attempts."
  end
end
