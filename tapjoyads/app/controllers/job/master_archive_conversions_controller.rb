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
    
    base_filename = "conversions_#{start_time.strftime('%Y-%m')}"
    local_filename = "tmp/#{base_filename}.sql"
    gzip_filename = "#{local_filename}.gz"
    
    # backup the conversions
    db_config = ActiveRecord::Base.configurations[Rails.env == 'production' ? 'production_slave_for_tapjoy_db' : Rails.env]
    mysql_cmd = "mysql -u #{db_config['username']} --password=#{db_config['password']} -h #{db_config['host']} #{db_config['database']}"
    mysql_cmd += " -e \"SELECT * FROM conversions WHERE created_at >= '#{start_time.to_s(:db)}' AND created_at < '#{end_time.to_s(:db)}'\""
    `#{mysql_cmd} > #{local_filename}`
    
    # compress the backup
    `gzip -f #{local_filename}`
    
    # pick a filename for s3, making sure not to overwrite anything
    bucket = S3.bucket(BucketNames::CONVERSION_ARCHIVES)
    while bucket.key("#{base_filename}.sql.gz").exists? do
      base_filename += '_2'
    end
    
    # upload to s3
    retries = 3
    begin
      bucket.put("#{base_filename}.sql.gz", open(gzip_filename))
    rescue RightAws::AwsError => e
      if retries > 0
        retries -= 1
        sleep 5
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
