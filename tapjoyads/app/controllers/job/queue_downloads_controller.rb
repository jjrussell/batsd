class Job::QueueDownloadsController < Job::SqsReaderController

  def initialize
    super QueueNames::DOWNLOADS
  end

  private

  def on_message(message)
    message = JSON.parse(message.body).symbolize_keys

    Downloader.get_strict(message[:url], message[:download_options].symbolize_keys)
  end

end
