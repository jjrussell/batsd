class Job::MasterArchiveConversionsController < Job::JobController
  
  def index
    Conversion.using_slave_db do
      if MonthlyAccounting.count == MonthlyAccounting.expected_count
        start_time = Conversion.minimum(:created_at).beginning_of_month
        end_time = Conversion.archive_cutoff_time
        while start_time < end_time do
          archive_conversions(start_time, start_time.next_month)
          start_time = start_time.next_month
        end
      end
    end
    
    render :text => 'ok'
  end
  
private
  
  def archive_conversions(start_time, end_time)
    return if Conversion.created_between(start_time, end_time).count == 0
    
    base_filename = "conversions_#{start_time.year}-#{start_time.month}"
    local_filename = "tmp/#{base_filename}.sdb"
    gzip_filename = "#{local_filename}.gz"
    
    # write each conversion's attributes to a file
    backup_file = File.open(local_filename, 'w')
    Conversion.created_between(start_time, end_time).find_each do |c|
      backup_file.puts(c.attributes.to_json)
    end
    backup_file.close
    
    # compress the backup
    `gzip -f #{local_filename}`
    
    # pick a filename for s3, making sure not to overwrite anything
    bucket = S3.bucket(BucketNames::CONVERSION_ARCHIVES)
    while bucket.key("#{base_filename}.sdb").exists? do
      base_filename += '_2'
    end
    
    # upload to s3
    retries = 3
    begin
      bucket.put("#{base_filename}.sdb", open(gzip_filename))
    rescue RightAws::AwsError => e
      if retries > 0
        retries -= 1
        retry
      else
        raise e
      end
    end
    
    # delete the conversion records
    Conversion.created_between(start_time, end_time).delete_all
  ensure
    `rm #{local_filename}`
    `rm #{gzip_filename}`
  end
  
end
