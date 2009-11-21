require 'patron'

module DownloadContent
  include Patron
  
  def download_content(url, headers = {}, timeout = 2)
    start_time = Time.now.utc
    Rails.logger.info "Downloading #{url}"
    sess = Session.new
    sess.timeout = timeout

    response = sess.get(url, headers)
    
    Rails.logger.info "Download complete (#{Time.now.utc - start_time}s)"
    
    return response.body
  end
end