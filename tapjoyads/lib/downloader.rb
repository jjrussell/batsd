class Downloader
  ##
  # Make a GET request to the specified url and return the contents of the response.
  def self.get(url, options = {})
    headers = options.delete(:headers) { {} }
    timeout = options.delete(:timeout) { 2 }
    internal_authenticate = options.delete(:internal_authenticate) { false }
    return_response = options.delete(:return_response) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
        
    start_time = Time.now.utc
    Rails.logger.info "Downloading #{url}"
    sess = Patron::Session.new
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
  # If the download fails, it will be retried automatically via sqs.
  def self.get_with_retry(url, download_options = {}, failure_message = nil)
    begin
      Downloader.get_strict(url, download_options)
    rescue Exception => e
      Rails.logger.info "Download failed. Error: #{e}"
      message = {:url => url, :download_options => download_options, :failure_message => failure_message}.to_json
      Sqs.send_message(QueueNames::FAILED_DOWNLOADS, message)
      Rails.logger.info "Added to FailedDownloads queue."
    end
  end
  
  ##
  # Download a url and return the response. Raises an exception if the response status is not normal.
  def self.get_strict(url, download_options = {})
    response = Downloader.get(url, download_options.merge({:return_response => true}))
    if response.status == 403
      Notifier.alert_new_relic(FailedToDownloadError, "Failed to download #{url}. 403 error.")
    elsif response.status < 200 or response.status > 399
      raise "#{response.status} error from #{url}"
    end
    
    return response
  rescue Exception => e
    mc_key = "failed_downloads.#{(Time.zone.now.to_f / 1.hour).to_i}"
    url_key = url.gsub(/\?.*$/, '')
    
    Mc.compare_and_swap(mc_key) do |failed_downloads|
      if failed_downloads
        failed_downloads[url_key] = (failed_downloads[url_key] || 0) + 1
        failed_downloads
      else
        { url_key => 1 }
      end
    end
    
    raise e
  end
  
end
