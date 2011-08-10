class Job::MasterCheckSyslogNgController < Job::JobController
  
  def index
    time = Time.zone.now - 1.hour
    bucket = S3.bucket(BucketNames::WEB_REQUESTS)
    
    prefix = "syslog-ng/#{time.to_s(:yyyy_mm_dd)}/#{time.strftime('%H')}-"
    count = bucket.keys(:prefix => prefix).size
    if count != 3
      Notifier.alert_new_relic(SyslogNgError, "there are #{count} files with prefix: #{prefix}", request, params)
    end
    
    render :text => 'ok'
  end
  
end
