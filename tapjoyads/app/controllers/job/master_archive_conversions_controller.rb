class Job::MasterArchiveConversionsController < Job::JobController

  def index
    render :text => 'ok' and return if MonthlyAccounting.count != MonthlyAccounting.expected_count

    Conversion.using_slave_db do
      start_time = Conversion.minimum(:created_at).beginning_of_month
      end_time = Conversion.backup_cutoff_time
      while start_time < end_time
        archive_conversions(start_time, start_time.next_month)
        start_time = start_time.next_month
      end
    end

    Conversion.drop_archived_partitions

    render :text => 'ok'
  end

  private

  def archive_conversions(start_time, end_time)
    base_filename = "conversions_#{start_time.strftime('%Y-%m')}"
    local_filename = "tmp/#{base_filename}.sql"
    gzip_filename = "#{local_filename}.gz"
    s3_filename = "#{base_filename}.sql.gz"

    bucket = S3.bucket(BucketNames::CONVERSION_ARCHIVES)
    return if bucket.objects[s3_filename].exists?

    expected_count = Conversion.created_between(start_time, end_time).count
    return if expected_count == 0

    db_config = ActiveRecord::Base.configurations[Rails.env.production? ? 'production_slave_for_tapjoy_db' : Rails.env]
    mysql_cmd = "mysql -u #{db_config['username']} --password=#{db_config['password']} -h #{db_config['host']} #{db_config['database']}"
    mysql_cmd += " -e \"SELECT * FROM conversions WHERE created_at >= '#{start_time.to_s(:db)}' AND created_at < '#{end_time.to_s(:db)}'\""
    `#{mysql_cmd} > #{local_filename}`

    backup_count = `wc -l #{local_filename}`.split[0].to_i - 1
    if backup_count != expected_count
      raise "failed to archive conversions from #{start_time.to_s(:db)} to #{end_time.to_s(:db)}, expected #{expected_count} but backed up #{backup_count}"
    end

    `gzip -f #{local_filename}`

    retries = 3
    begin
      bucket.objects[s3_filename].write(:file => gzip_filename)
    rescue AWS::Errors::Base => e
      if retries > 0
        retries -= 1
        sleep 5
        retry
      else
        raise e
      end
    end
  ensure
    `rm #{local_filename}`
    `rm #{gzip_filename}`
  end

end
