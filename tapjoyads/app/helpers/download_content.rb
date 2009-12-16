require 'patron'

module DownloadContent
  include Patron
  include RightAws
  
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
  def download_with_retry(url, download_options = {}, retry_options = {}, action_options = {})
    num_retries = retry_options.delete(:retries) { 0 }
    should_alert = retry_options.delete(:alert) { false }
    final_action = retry_options.delete(:final_action)
    raise "Unknown retry_options #{options.keys.join(', ')}" unless retry_options.empty?
    
    begin
      response = download_content(url, download_options.merge({:return_response => true}))
      if response.status == 403
        call_final_action(final_action, '403', retry_options)
      elsif response.status < 200 or response.status > 399
        raise "#{response.status} error"
      else
        call_final_action(final_action, 'success', action_options)
      end
    rescue Exception => e
      Rails.logger.info "Download failed. Error: #{e}"
      if num_retries > 0
        retry_options[:retries] = num_retries - 1
        message = {:url => url, :download_options => download_options, 
            :retry_options => retry_options, :action_options => action_options}.to_json
        SqsGen2.new.queue(QueueNames::FAILED_DOWNLOADS).send_message(message)
        Rails.logger.info "Added to FailedDownloads queue."
      else
        if retry_options[:alert]
          # TODO: Alert via newrelic.
        end
        call_final_action(final_action, 'max_retries', retry_options)
      end
    end
  end
  
  private
  
  def call_final_action(action, status, options)
    Rails.logger.info "Calling final action: #{action}"
    case action
    when 'send_currency_download_complete'
      send_currency_download_complete(status, options)
    when nil
      Rails.logger.info "No final action to call."
    else
      raise "Unknown final action: #{action}"
    end
  end
  
  def send_currency_download_complete(status, options)
    if status == 'max_retries'
      app = App.new(options[:app_id])
      app.put('send_currency_error', status)
      app.save
    end
    
    reward = Reward.new(options[:reward_id])
    reward.put('send_currency_status', status)
    reward.save
  end
end