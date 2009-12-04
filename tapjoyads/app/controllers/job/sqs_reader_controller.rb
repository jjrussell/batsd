class Job::SqsReaderController < Job::JobController
  include RightAws

  def initialize(queue_name)
    @queue_name = queue_name
  end

  def index
    now = Time.now
    sqs = SqsGen2.new
    queue = sqs.queue(@queue_name, false)
    messages = queue.receive_messages(10, 60)
    messages.each do |message|
      Rails.logger.info "#{@queue_name} message recieved: #{message.to_s}"
      begin
        on_message(message)
        message.delete
      rescue Exception => e
        Rails.logger.warn "Error processing message. Error: #{e}"
      end
    end
    
    render :text => 'ok'
  end

end