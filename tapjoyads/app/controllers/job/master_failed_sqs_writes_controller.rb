##
# Reads messages from failed-sqs-writes bucket, and writes them back to the queue that
# they orignially failed to write to.
class Job::MasterFailedSqsWritesController < Job::JobController

  def index
    bucket = S3.bucket(BucketNames::FAILED_SQS_WRITES)
    bucket.keys.each do |key|
      json_string = bucket.get(key.to_s).to_s
      begin
        json = JSON.parse(json_string)
      rescue JSON::ParserError => e
        bucket.delete_folder(key.to_s)
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
        bucket.delete_folder(key.to_s)
      end
    end

    render :text => 'OK'
  end
end
