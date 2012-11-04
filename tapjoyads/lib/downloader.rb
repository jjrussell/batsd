class Downloader
  ##
  # Make a GET request to the specified url and return the contents of the response.
  #
  def self.get(url, options = {})
    headers  = options.delete(:headers) { {} }
    timeout  = options.delete(:timeout) { 2 }
    offer_id = options.delete(:offer_id) { nil }
    url_type = options.delete(:url_type) { nil }

    internal_authenticate = options.delete(:internal_authenticate) { false }
    return_response = options.delete(:return_response) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    start_time = Time.zone.now
    headers.merge!({ 'User-Agent' => 'Tapjoy Downloader' })
    Rails.logger.info "Downloading (GET) #{url}"

    sess = Patron::Session.new
    sess.timeout = timeout
    sess.insecure = true

    if internal_authenticate
      sess.username = 'internal'
      sess.password = AuthenticationHelper::USERS[sess.username]
      sess.auth_type = :digest
    end

    response = sess.get(url, headers)

    Rails.logger.info "Download complete (#{Time.zone.now - start_time}s)"

    # REMOVEME -KB
    if offer_id == '2fb7a07a-3878-42c3-b672-03ab39f5b918'
      WebRequest.new(:time => Time.zone.now).tap do |wr|
        wr.path             = "#{url_type}_attempt"
        wr.offer_id         = offer_id
        wr.callback_url     = url
        wr.http_status_code = response.status
        wr.save
      end
    end

    return return_response ? response : response.body
  end

  def self.post(url, data, options = {})
    headers = options.delete(:headers) { {} }
    timeout = options.delete(:timeout) { 2 }
    return_response = options.delete(:return_response) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    start_time = Time.zone.now
    headers.merge!({ 'User-Agent' => 'Tapjoy Downloader/0.1/downloader/0.1/1' }) #needed for GFan api

    Rails.logger.info "Downloading (POST) #{url}"

    sess = Patron::Session.new
    sess.timeout = timeout

    response = sess.post(url, data, headers)

    Rails.logger.info "Download complete (#{Time.zone.now - start_time}s)"

    return return_response ? response : response.body
  end

  ##
  # Makes a GET request to url. No data is returned.
  # If the download fails, it will be retried automatically via sqs.
  def self.get_with_retry(url, download_options = {})
    begin
      Downloader.get_strict(url, download_options)
    rescue Exception => e
      Rails.logger.info "Download failed. Error: #{e}"
      queue_get_with_retry(url, download_options)
    end
  end
  ##
  # Download a url and return the response. Raises an exception if the response status is not normal.
  def self.post_strict(url, data = {}, download_options = {})
    response = Downloader.post(url, data, download_options.merge({:return_response => true}))
    if response.status == 403
      Notifier.alert_new_relic(FailedToDownloadError, "Failed to download #{url} with data #{data.inspect}. 403 error.")
    elsif response.status < 200 or response.status > 399
      raise "#{response.status} error from #{url} using data #{data.inspect}"
    end

    return response
  end

  ##
  # Download a url and return the response. Raises an exception if the response status is not normal.
  def self.get_strict(url, download_options = {})
    response = Downloader.get(url, download_options.merge({:return_response => true}))
    if response.status == 403
      Notifier.alert_new_relic(FailedToDownloadError, "Failed to download #{url}. 403 error.")
    elsif response.status.to_i < 200 or response.status.to_i > 399
      raise "#{response.status} error from #{url}"
    end

    return response
  end

  def self.queue_get_with_retry(url, download_options = {})
    message = { :url => url, :download_options => download_options }
    Sqs.send_message(QueueNames::DOWNLOADS, message.to_json)
    Rails.logger.info "Added to Downloads queue."
  end

  def self.queue_with_retry_until_successful(url, method=:get, data={}, download_options={})
    message = {:url => url, :method => method, :data => data, :download_options => download_options}
    Sqs.send_message(QueueNames::DOWNLOADS, message.to_json)
    Rails.logger.info "Added to Downloads queue."
  end

end
