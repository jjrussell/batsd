class Job::QueueCacheOffersController < Job::SqsReaderController

  def initialize
    super QueueNames::CACHE_OFFERS
  end

private

  def on_message(message)
    currency = Currency.find(message.to_s, :include => [ :currency_group, :app ])
    currency.cache_offers
  end
end
