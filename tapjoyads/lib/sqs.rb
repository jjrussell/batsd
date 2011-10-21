##
# Functionality to write a message to sqs. If writing to sqs fails, the message will be stored in
# the failed-sqs-writes s3 bucket.
class Sqs

  def self.reset_connection
    @@sqs = RightAws::SqsGen2.new(nil, nil, { :multi_thread => true, :port => 80, :protocol => 'http' })
    @@queues = {}
  end

  cattr_reader :sqs
  self.reset_connection

  def self.queue(queue_name, create = true, visibility = nil)
    if @@queues[queue_name].nil? || @@queues[queue_name].name != queue_name
      @@queues[queue_name] = @@sqs.queue(queue_name, create, visibility)
    end
    @@queues[queue_name]
  end

  def self.send_message(queue_name, message, write_to_s3_on_failure = true)
    queue = Sqs.queue(queue_name)

    num_retries = 1
    begin
      queue.send_message(message)
    rescue Exception => e
      if num_retries > 0
        num_retries -= 1
        retry
      end

      # If we've gotten here, the message has failed to send to sqs. Write the message to S3.
      Notifier.alert_new_relic(FailedToWriteToSqsError, "#{queue_name} - #{message}")

      if write_to_s3_on_failure
        s3_message = {:queue_name => queue_name, :message => message}.to_json

        bucket = S3.bucket(BucketNames::FAILED_SQS_WRITES)
        bucket.put(UUIDTools::UUID.random_create.to_s, s3_message)
      else
        raise e
      end
    end
  end

  def self.read_messages(queue_name)
    q = queue(queue_name)
    loop do
      message = q.receive
      unless message.to_s == ''
        yield message
      end
    end
  end

  def self.delete_messages(queue_name, regex)
    read_messages(queue_name) do |message|
      if message.to_s =~ regex
        puts message.to_s
        message.delete
      end
    end
  end

end
