##
# Reads messages from failed-sqs-writes bucket, and writes them back to the queue that 
# they orignially failed to write to.
class Job::MasterFailedSqsWritesController < Job::JobController
  include RightAws
  include NewRelicHelper
  
  def index
    bucket = S3.new.bucket('failed-sqs-writes')
    bucket.keys.each do |key|
      json_string = bucket.get(key.to_s).to_s
      json = JSON.parse(json_string)
      message = json['message']
      queue_name = json['queue_name']
      
      begin
        SqsGen2.new.queue(queue_name).send_message(message)
        bucket.delete_folder(key.to_s)
      rescue RightAws::AwsError => e
        log_line = "FailedSqsWrites job failed to write message #{message} to queue #{queue_name}, with error: #{e}"
        Rails.logger.info log_line
        alert_new_relic(FailedToWriteToSqsError, log_line)
      end
    end
    
    render :text => 'OK'
  end
end