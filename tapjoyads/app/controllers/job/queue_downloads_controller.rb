class Job::QueueDownloadsController < Job::SqsReaderController

  def initialize
    super QueueNames::DOWNLOADS

    # One download failure shouldn't negatively affect all the others, that's not very nice.
    @raise_on_error = false
  end

  private

  def on_message(message)
    message = JSON.parse(message.body).symbolize_keys

    Downloader.get_strict(message[:url], message[:download_options].symbolize_keys)
  end

end
