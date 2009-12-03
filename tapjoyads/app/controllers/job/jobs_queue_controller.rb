class Job::JobsQueueController < Job::SqsReaderController
  def initialize
    super QueueNames::JOBS
  end
  
  private
  
  def on_message(message)
    Rails.logger.info "Message: " + message
    
    json = JSON.parse(message)
    path = json['path']
    job_params = json['params']
    
    params_array = []
    job_params.each do |key, value|
      params_array.push("#{key}=#{value}")
    end
    params_string = params_array.join('&')
    
    sess = Patron::Session.new
    sess.base_url = request.host_with_port
    sess.timeout = 2
    sess.username = 'internal'
    sess.password = AuthenticationHelper::USERS[sess.username]
    sess.auth_type = :digest
    
    full_path = "/job/#{path}?#{params_string}"
    begin
      sess.get(full_path)
    rescue Patron::TimeoutError
      # Jobs may take a long time. We don't want to throw an error on timeouts.
      logger.info "Timeout when calling #{full_path}"
    end
  end
  
end