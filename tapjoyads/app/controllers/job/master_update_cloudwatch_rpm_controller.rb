class Job::MasterUpdateCloudwatchRpmController < Job::JobController

  def index
    rpms = $redis.mget(*$redis.keys('request_counters:*')).map(&:to_i)
    mean = rpms.mean.to_i

    metrics = [
      {
        'MetricName' => 'api-rpm',
        'Unit' => 'Count',
        'Value' => mean
      }
    ]
    CloudWatch.put_metric_data('TJOPS', metrics)

    render :text => 'ok'
  end

end
