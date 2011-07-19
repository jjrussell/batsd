class Job::QueueActivemqWritesController < Job::SqsReaderController
  
  def initialize
    super QueueNames::FAILED_ACTIVEMQ_WRITES
  end
  
private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    Activemq.publish_message(json['queue'], json['message'], false)
  end
  
end
