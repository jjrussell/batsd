##
# Functionality to write a message to sqs. If writing to sqs failes, the message will be stored in
# the failed-sqs-writes s3 bucket.
module SqsHelper
  include RightAws
  
  def send_to_sqs(queue_name, message)
    sqs = SqsGen2.new(nil, nil, :multi_thread => true)
    queue = sqs.queue(queue_name)
    
    num_retries = 1
    
    begin
      queue.send_message(message)
    rescue
      if num_retries > 0
        num_retries -= 1
        retry
      end
      
      # If we've gotten here, the message has failed to send to sqs. Write the message to S3.
      Notifier.alert_new_relic(FailedToWriteToSqsError)
      
      s3_message = {:queue_name => queue_name, :message => message}.to_json
      
      s3 = RightAws::S3.new(nil, nil, :multi_thread => true)
      bucket = s3.bucket('failed-sqs-writes')
      bucket.put(UUIDTools::UUID.random_create.to_s, s3_message)
    end
  end
end