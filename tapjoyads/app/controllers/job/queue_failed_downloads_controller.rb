class Job::QueueFailedDownloadsController < Job::SqsReaderController

  def initialize
    super QueueNames::FAILED_DOWNLOADS
  end

  private

  def on_message(message)
    json = JSON.parse(message.to_s)

    url = json['url']
    download_options = json['download_options'].symbolize_keys

    Downloader.get_strict(url, download_options)
  end
end
