require 'patron'

module DownloadContent
  include Patron
  
  def download_content(url, options = {})
    headers = options.delete(:headers) { {} }
    timeout = options.delete(:timeout) { 2 }
    internal_authenticate = options.delete(:internal_authenticate) { false }
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
    
    return response.body
  end
  
  ##
  # Downloads data from url, without returning the data. If the download fails, it will be retried
  # automatically via sqs.
  # TODO: actually implement retrying.
  def send_to_url(url, download_options = {}, send_options = {})
    download_content(url, download_options)
  end
end