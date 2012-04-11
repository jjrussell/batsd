class Job::QueueDownloadsController < Job::SqsReaderController

  def initialize
    super QueueNames::DOWNLOADS
  end

  private

  def on_message(message)
    message = Marshal.restore(Base64::decode64(message.body))

    Downloader.get_strict(message[:url], message[:download_options])
  end

end
