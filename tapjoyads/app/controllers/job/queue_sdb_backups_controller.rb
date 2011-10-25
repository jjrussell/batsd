class Job::QueueSdbBackupsController < Job::SqsReaderController

  before_filter :limit_concurrent_jobs, :only => :index

  def initialize
    super(QueueNames::SDB_BACKUPS)
    @num_reads = 1
  end

private

  def on_message(message)
    json = JSON.parse(message.to_s)
    domain_name = json['domain_name']
    s3_bucket = json['s3_bucket']
    backup_options = json['backup_options']
    backup_options.symbolize_keys!

    message.delete

    SdbBackup.backup_domain(domain_name, s3_bucket, backup_options)
  end

  def limit_concurrent_jobs
    if Dir.glob("#{RAILS_ROOT}/tmp/*.sdb").length > 5
      render :text => 'ok'
    end
  end

end
