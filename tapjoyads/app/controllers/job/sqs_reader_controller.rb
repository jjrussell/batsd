class Job::SqsReaderController < Job::JobController
  include RightAws
  @@queue = nil

  def initialize(queue_name)
    @queue_name = queue_name
  end

  def index
    queue = nil
    retries = 3
    begin
      queue = SqsGen2.new.queue(@queue_name)
    rescue AwsError => e
      Rails.logger.info "Error creating queue object: #{e}"
      if retries > 0
        Rails.logger.info "Retrying up to #{retries} more times."
        retries -= 1
        retry
      else
        raise e
      end
    end while queue == nil
    
    messages = queue.receive_messages(10)
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