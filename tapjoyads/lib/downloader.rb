class Downloader
  include HTTParty

  INTERNAL_AUTH_USER = 'internal'

  ##
  # Make a GET request to the specified url and return the contents of the response.
  #
  # Options can include the following:
  #  :headers - Hash of extra header values
  #  :timeout - timeout in seconds
  #  :internal_authenticate - boolean for using authentication settings from AuthenticationHelper
  #  :return_response - boolean to return the response object, body is returned if otherwise
  def self.get(url, options = {})
    return_response = options.delete(:return_response) { false }
    options = setup(options)

    Rails.logger.info "Downloading (GET) #{url}"

    start_time = Time.zone.now
    response = super(url, options)

    Rails.logger.info "Download complete (#{Time.zone.now - start_time}s)"

    return return_response ? response : response.body
  end

  ##
  # Make a POST request to the specified url and return the contents of the response.
  #
  # Options can include the following:
  #  :headers - Hash of extra header values
  #  :timeout - timeout in seconds
  #  :internal_authenticate - boolean for using authentication settings from AuthenticationHelper
  #  :return_response - boolean to return the response object, body is returned if otherwise
  def self.post(url, data, options = {})
    return_response = options.delete(:return_response) { false }
    options = setup(options)

    Rails.logger.info "Downloading (POST) #{url}"

    start_time = Time.zone.now
    response = super(url, data, options)

    Rails.logger.info "Download complete (#{Time.zone.now - start_time}s)"

    return return_response ? response : response.body
  end

  ##
  # Makes a GET request to url. No data is returned.
  # If the download fails, it will be retried automatically via sqs.
  #
  # See #self.get_strict
  def self.get_with_retry(url, download_options = {}, failure_message = nil)
    begin
      get_strict(url, download_options)
    rescue Exception => e
      Rails.logger.info "Download failed. Error: #{e}"
      message = {:url => url, :download_options => download_options, :failure_message => failure_message}.to_json
      Sqs.send_message(QueueNames::FAILED_DOWNLOADS, message)
      Rails.logger.info "Added to FailedDownloads queue."
    end
  end

  ##
  # Download a url and return the response. Raises an exception if the response status is not normal.
  #
  # See #self.get
  def self.get_strict(url, download_options = {})
    response = get(url, download_options.merge({:return_response => true}))
    if response.code == 403
      Notifier.alert_new_relic(FailedToDownloadError, "Failed to download #{url}. 403 error.")
    elsif response.code < 200 or response.code > 399
      raise "#{response.code} error from #{url}"
    end

    return response
  end

  private
  def self.setup(options)
    options.merge!({
      :headers => {},
      :timeout => 2
    })

    options[:headers].merge!({ 'User-Agent' => 'Tapjoy Downloader' })
    options[:digest_auth] = authentication if options.delete(:internal_authenticate)

    options
  end

  def self.authentication
    {
      :username => INTERNAL_AUTH_USER,
      :password => AuthenticationHelper::USERS[INTERNAL_AUTH_USER]
    }
  end
end
