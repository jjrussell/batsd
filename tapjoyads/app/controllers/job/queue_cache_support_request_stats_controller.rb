class Job::QueueCacheSupportRequestStatsController < Job::SqsReaderController

  def initialize
    super QueueNames::CACHE_SUPPORT_REQUEST_STATS
  end

  private

  def on_message(message)
    SupportRequestStats.cache_all
  end

end
