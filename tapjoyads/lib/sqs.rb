class Sqs

  def self.queues
    AWS::SQS.new.queues
  end

  def self.queue(queue_name)
    queues[queue_name]
  end

  def self.create_queue(queue_name, visibility_timeout)
    queues.create("#{RUN_MODE_PREFIX}#{queue_name}", { :default_visibility_timeout => visibility_timeout })
  end

  def self.send_message(queue_name, message, write_to_s3_on_failure = true)
    num_retries = 1
    begin
      queue(queue_name).send_message(message)
    rescue Exception => e
      if num_retries > 0
        num_retries -= 1
        retry
      end

      Notifier.alert_new_relic(FailedToWriteToSqsError, "#{queue_name} - #{message}")

      if write_to_s3_on_failure
        s3_message = { :queue_name => queue_name, :message => message }.to_json
        bucket = S3.bucket(BucketNames::FAILED_SQS_WRITES)
        bucket.objects[UUIDTools::UUID.random_create.to_s].write(:data => s3_message)
      else
        raise e
      end
    end
  end

  def self.read_messages(queue_name)
    q = queue(queue_name)
    loop do
      message = q.receive_message
      yield message unless message.nil?
    end
  end

  def self.delete_messages(queue_name, regex)
    read_messages(queue_name) do |message|
      if message.body =~ regex
        puts message.body
        message.delete
      end
    end
  end

end
