class Job::QueueCacheOptimizedOfferListController < Job::SqsReaderController
  def initialize
    super QueueNames::CACHE_OPTIMIZED_OFFER_LIST
  end

  private

  def on_message(message)
    s3_optimization_key = message.body
    begin
      OptimizedOfferList.cache_offer_list(s3_optimization_key)
    rescue
      Notifier.alert_new_relic(OptimizedOfferCachingFailed, message.body)
    end
  end
end
