class Job::QueueCacheOptimizedOfferListController < Job::SqsReaderController
  def initialize
    super QueueNames::CACHE_OPTIMIZED_OFFER_LIST
  end

  private

  def on_message(message)
    s3_optimization_key = message.body
    OptimizedOfferList.cache_offer_list(s3_optimization_key)
  end
end
