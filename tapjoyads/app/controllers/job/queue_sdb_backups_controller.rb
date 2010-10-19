class Job::QueueSdbBackupsController < Job::SqsReaderController
  
  def initialize
    super(QueueNames::SDB_BACKUPS)
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
  
end
