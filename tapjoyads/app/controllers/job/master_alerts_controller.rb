class Job::MasterAlertsController < Job::JobController
  def index
    alerts.each do |alert|
      begin
        rows = vertica.query(alert[:query]).rows
      rescue Vertica::Error::QueryError
        next
      end

      send(alert) if rows.length > 0
    end

    render :text => 'ok'
  end

  private

  def alerts
    alerts_keys.map { |key| s3_alert(key) }.flatten
  end

  def send(alert)
    if alert[:recipients_field]
      direct_recipients = rows.collect {|row| row[alert[:recipients_field]] }.uniq

      direct_recipients.each do |recipient|
        TapjoyMailer.deliver_alert(alert, rows.select {|row| row[alert[:recipients_field]] == recipient}, recipient)
      end
    else
      TapjoyMailer.deliver_alert(alert, rows, alert[:recipients])
    end
  end

  def s3_alert(key)
    json = alerts_bucket.objects[key].read
    JSON.parse(json)
  end

  def alerts_keys
    alerts_bucket.objects.map(&:key).reject { |keys| keys.last == "/" }
  end

  def alerts_bucket
    @alerts_bucket ||= S3.bucket(BucketNames::ALERTS)
  end

  def vertica
    @vertica ||= VerticaCluster.get_connection
  end
end
