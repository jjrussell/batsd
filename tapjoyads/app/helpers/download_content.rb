require 'patron'

module DownloadContent
  include Patron
  
  def download_content(url, options = {})
    headers = options[:headers] || {}
    timeout = options[:timeout] || 2
    internal_authenticate = options[:internal_authenticate] || false
    
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
end