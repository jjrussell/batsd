class Job::SqsReaderController < Job::JobController
  include RightAws

  def initialize(queue_name)
    @queue_name = queue_name
  end

  def index
    sqs = SqsGen2.new
    queue = sqs.queue(@queue_name)
    messages = queue.receive_messages(10, 60)
    messages.each do |message|
      begin
        on_message(message.to_s)
        message.delete
      rescue Exception => e
        Rails.logger.warn "Error in queue: #{@queue_name} while processing message: #{message.to_s}. Error: #{e}"
      end
    end
    
    render :text => 'ok'
  end

end