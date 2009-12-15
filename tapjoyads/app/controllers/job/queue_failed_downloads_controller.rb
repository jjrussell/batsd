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
    string_retry_options = json['retry_options']
    string_action_options = json['action_options']
    
    # Convert all keys to symbols, rather than strings.
    string_download_options.each do |key, value|
      download_options[key.to_sym] = value
    end
    string_retry_options.each do |key, value|
      retry_options[key.to_sym] = value
    end
    string_action_options.each do |key, value|
      action_options[key.to_sym] = value
    end
    
    download_with_retry(url, download_options, retry_options, action_options)
  end
end
