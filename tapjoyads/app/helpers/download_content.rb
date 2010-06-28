require 'patron'

module DownloadContent
  include Patron
  include NewRelicHelper
  include SqsHelper
  
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
  def download_with_retry(url, download_options = {})
    begin
      download_strict(url, download_options)
    rescue Exception => e
      Rails.logger.info "Download failed. Error: #{e}"
      message = {:url => url, :download_options => download_options}.to_json
      send_to_sqs(QueueNames::FAILED_DOWNLOADS, message)
      Rails.logger.info "Added to FailedDownloads queue."
    end
  end
  
  ##
  # Download a url and return the response. Raises an exception if the response status is not normal.
  def download_strict(url, download_options = {})
    response = download_content(url, download_options.merge({:return_response => true}))
    if response.status == 403
      alert_new_relic(FailedToDownloadError, "Failed to download #{url}. 403 error.")
    elsif response.status < 200 or response.status > 399
      raise "#{response.status} error from #{url}"
    end
    
    return response
  end
end