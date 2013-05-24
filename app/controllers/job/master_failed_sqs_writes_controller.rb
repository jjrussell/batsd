class Job::MasterFailedSqsWritesController < Job::JobController

  def index
    bucket = S3.bucket(BucketNames::FAILED_SQS_WRITES)
    bucket.objects.each do |obj|
      json_string = obj.read
      begin
        json = JSON.parse(json_string)
      rescue JSON::ParserError => e
        obj.delete
        Notifier.alert_new_relic(e.class, e.message, request, params)
        next
      end

      message = json['message']
      queue_name = json['queue_name']

      begin
        Sqs.send_message(queue_name, message, false)
      rescue
        # don't delete the key because the SQS write failed
      else
        obj.delete
      end
    end

    render :text => 'OK'
  end

end
