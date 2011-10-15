class Job::MasterArchiveConversionsController < Job::JobController

  def index
    render :text => 'ok' and return if MonthlyAccounting.count != MonthlyAccounting.expected_count

    # backup anything before the archive cutoff date
    Conversion.using_slave_db do
      start_time = Conversion.minimum(:created_at).beginning_of_month
      end_time = Conversion.archive_cutoff_time
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
    expected_count = Conversion.created_between(start_time, end_time).count
    return if expected_count == 0

    base_filename = "conversions_#{start_time.strftime('%Y-%m')}"
    local_filename = "tmp/#{base_filename}.sql"
    gzip_filename = "#{local_filename}.gz"

    # backup the conversions
    db_config = ActiveRecord::Base.configurations[Rails.env == 'production' ? 'production_slave_for_tapjoy_db' : Rails.env]
    mysql_cmd = "mysql -u #{db_config['username']} --password=#{db_config['password']} -h #{db_config['host']} #{db_config['database']}"
    mysql_cmd += " -e \"SELECT * FROM conversions WHERE created_at >= '#{start_time.to_s(:db)}' AND created_at < '#{end_time.to_s(:db)}'\""
    `#{mysql_cmd} > #{local_filename}`

    # make sure the backup is complete
    backup_count = `wc -l #{local_filename}`.split[0].to_i - 1
    if backup_count != expected_count
      raise "failed to archive conversions from #{start_time.to_s(:db)} to #{end_time.to_s(:db)}, expected #{expected_count} but backed up #{backup_count}"
    end

    # compress the backup
    `gzip -f #{local_filename}`

    # pick a filename for s3, making sure not to overwrite anything
    bucket = S3.bucket(BucketNames::CONVERSION_ARCHIVES)
    while bucket.objects["#{base_filename}.sql.gz"].exists?
      base_filename += '_2'
    end

    # upload to s3
    bucket.objects["#{base_filename}.sql.gz"].write(:file => gzip_filename)
  ensure
    `rm #{local_filename}`
    `rm #{gzip_filename}`
  end

end
