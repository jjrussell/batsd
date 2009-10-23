require 'patron'

module DownloadContent
  include Patron
  
  def download_content(uri, headers = {}, timeout = 2)
    start_time = Time.now
    Rails.logger.info "Downloading #{uri.to_s}"
    sess = Session.new
    sess.base_url = uri.host
    sess.timeout = 2
    
    response = sess.get(uri.request_uri, headers)
    
    Rails.logger.info "Downloaded complete (#{Time.now - start_time}s)"
    
    return response.body
  end
end