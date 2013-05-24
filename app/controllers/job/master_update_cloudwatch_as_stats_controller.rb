class Job::MasterUpdateCloudwatchAsStatsController < Job::JobController
  REQUEST_QUEUE_TIME_THRESHOLD = 10.0

  # Failures raise exceptions while getting the metrics
  # We want to store request queue time even if we don't get cpu,
  # however we don't store cpu time unless we integrate request queue time.
  def index
    queue_time = newrelic_request_queue_time
    metrics = [
      {
        'MetricName' => 'api-newrelic-queue-time',
        'Unit' => 'Milliseconds',
        'Value' => queue_time
      }
    ]

    # Scale down metric - if queuing, crank up the metric
    begin
      scale_down_metric = api_cpu_utilization
      scale_down_metric = 100.0 if queue_time >= Job::MasterUpdateCloudwatchAsStatsController::REQUEST_QUEUE_TIME_THRESHOLD
      metrics << {
        'MetricName' => 'api-scale-down-metric',
        'Unit' => 'Percent',
        'Value' => scale_down_metric
      }
    rescue
    end

    # Send one or both metrics to CloudWatch
    try_three_times do
      response = CloudWatch.put_metric_data('TJOPS', metrics)
      CloudWatch.parse_xml_response(response.body, "metrics not stored in CloudWatch: #{response.body}")
    end

    render :text => 'ok'
  end

  private
  def newrelic_request_queue_time
    try_three_times do
      request_queue_time = NewrelicMetric.get('WebFrontend/QueueTime', 'average_value')
      (request_queue_time * 1000).round(2)
    end
  end

  def api_cpu_utilization
    try_three_times do
      now = Time.now.utc

      response = CloudWatch.response_generator(
         :action => 'GetMetricStatistics',
         :params => {'Namespace'=>'AWS/EC2',
                     'MetricName'=>'CPUUtilization',
                     'StartTime'=>(now-60).iso8601,
                     'EndTime'=>now.iso8601,
                     'Period'=>'60',
                     'Statistics.member.1'=>'Average',
                     'Dimensions.member.1.Name'=>'AutoScalingGroupName',
                     'Dimensions.member.1.Value'=>'ApiGroup'})
      stat = CloudWatch.parse_xml_response(response.body, 'unable to get cpu api')
      cpu_util = stat['GetMetricStatisticsResponse']['GetMetricStatisticsResult']['Datapoints']['member']['Average']
      cpu_util.to_f.round(2)
    end
  end

  # These external api's fail quite often, retrying does no harm.
  def try_three_times
    retry_times = 0
    begin
      yield
    rescue => e
      retry_times = retry_times + 1
      retry unless retry_times >= 3
      raise e
    end
  end
end
