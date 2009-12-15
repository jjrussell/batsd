require 'patron'

module DownloadContent
  include Patron
  
  def download_content(url, options = {})
    headers = options.delete(:headers) { {} }
    timeout = options.delete(:timeout) { 2 }
    internal_authenticate = options.delete(:internal_authenticate) { false }
    return_response = options.delete(:return_response) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
        
    start_time = Time.now.utc
    Rails.logger.info "Downloading #{url}"
    sess = Session.new
    sess.timeout = timeout

    if internal_authenticate
      sess.username = 'internal'
      sess.password = AuthenticationHelper::USERS[sess.username]
      sess.auth_type = :digest
    end

    response = sess.get(url, headers)
    
    Rails.logger.info "Download complete (#{Time.now.utc - start_time}s)"
    
    return response if return_response
    return response.body
  end
  
  ##
  # Makes a GET request to url. No data is returned.
  # If the download fails, it will be retried automatically via sqs, 
  # as long as retry_options[:retries] > 0.
  def download_with_retry(url, download_options = {}, retry_options = {})
    num_retries = retry_options.delete(:retries) { 0 }
    should_alert = retry_options.delete(:alert) { false }
    
    raise "Unknown options #{retry_options.keys.join(', ')}" unless retry_options.empty?
    
    begin
      response = download_content(url, download_options.merge({:return_response => true}))
      if response.status == 403
        call_fail_action(retry_options)
      elsif response.status < 200 or response.status > 399
        raise "#{response.status} error"
      end
    rescue Exception => e
      Rails.logger.info "Download failed. Error: #{e}"
      num_retries = retry_options[:retries]
      if num_retries > 0
        retry_options[:retries] = num_retries - 1
        message = {:url => url, :download_options => download_options, 
            :retry_options => retry_options}.to_json
        SqsGen2.new.queue(QueueNames::FAILED_DOWNLOADS).send_message(message)
      else
        if retry_options[:alert]
          # TODO: Alert via newrelic.
        end
        call_fail_action(retry_options)
      end
    end
  end
  
  private
  
  def call_fail_action(retry_options)
    case retry_options[:fail_action]
    when :mark_app_callback_dead
      mark_app_callback_dead(retry_options[:app_id])
    end
  end
  
  def mark_app_callback_dead(app_id)
    Rails.logger.info "Mark app dead: #{app_id}"
  end
end