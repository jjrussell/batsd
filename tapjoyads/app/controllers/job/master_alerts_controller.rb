class Job::MasterAlertsController < Job::JobController
  def index
    alerts.each { |alert| alert.run }

    render :text => 'ok'
  end

  private

  def alerts
    alerts_keys.map { |key| s3_alert(key) }.flatten
  end

  def s3_alert(key)
    json = alerts_bucket.objects[key].read
    JSON.parse(json).map { |alert| Alert.new(alert) }
  end

  def alerts_keys
    alerts_bucket.objects.map(&:key).reject { |keys| keys.last == "/" }
  end

  def alerts_bucket
    @alerts_bucket ||= S3.bucket(BucketNames::ALERTS)
  end

end
