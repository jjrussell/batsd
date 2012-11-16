class Job::QueueCacheExternalPublishersController < Job::SqsReaderController

  def initialize
    super QueueNames::CACHE_EXTERNAL_PUBLISHERS
  end

  private

  def on_message(message)
    ExternalPublisher.cache
  end

end
