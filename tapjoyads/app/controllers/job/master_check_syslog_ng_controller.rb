class Job::MasterCheckSyslogNgController < Job::JobController
  
  def index
    now = Time.zone.now
    bucket = S3.bucket(BucketNames::WEB_REQUESTS)
    
    prefix = "syslog-ng/#{now.to_s(:yyyy_mm_dd)}/#{now.strftime('%H')}-"
    count = bucket.keys(:prefix => prefix).size
    if count != 3
      Notifier.alert_new_relic(SyslogNgError, "there are #{count} files with prefix: #{prefix}", request, params)
    end
    
    render :text => 'ok'
  end
  
end
