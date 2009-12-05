class Job::SqsReaderController < Job::JobController
  include RightAws
  @@queue = nil

  def initialize(queue_name)
    unless @@queue
      @@queue = SqsGen2.new.queue(queue_name)
    end
  end

  def index
    messages = @@queue.receive_messages(10, 60)
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