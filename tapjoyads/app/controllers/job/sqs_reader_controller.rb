class Job::SqsReaderController < Job::JobController
  include RightAws
  @@queue = nil

  def initialize(queue_name)
    @queue_name = queue_name
  end

  def index
    queue = nil
    begin
      queue = SqsGen2.new.queue(@queue_name)
    end while queue == nil
    
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

  def run_job
    on_message(params[:message])
    
    render :text => 'ok'
  end

end