class Job::QueueFailedDownloadsController < Job::SqsReaderController
  include DownloadContent
  
  def initialize
    super QueueNames::FAILED_DOWNLOADS
  end
  
  private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    
    download_options = {}
    retry_options = {}
    action_options = {}
    url = json['url']
    string_download_options = json['download_options']
    
    # Convert all keys to symbols, rather than strings.
    string_download_options.each do |key, value|
      download_options[key.to_sym] = value
    end
    
    download_strict(url, download_options)
  end
end
