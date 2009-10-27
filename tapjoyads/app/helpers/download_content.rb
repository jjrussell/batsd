require 'patron'

module DownloadContent
  include Patron
  
  def download_content(url, headers = {}, timeout = 2)
    start_time = Time.now
    Rails.logger.debug "Downloading #{url}"
    sess = Session.new
    sess.timeout = timeout

    response = sess.get(url, headers)
    
    Rails.logger.debug "Downloaded complete (#{Time.now - start_time}s)"
    
    return response.body
  end
end