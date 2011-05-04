class Job::QueueCacheOffersController < Job::SqsReaderController
  
  def initialize
    super QueueNames::CACHE_OFFERS
  end
  
private
  
  def on_message(message)
    app = App.find(message.to_s)
    Offer.cache_offers_for_app(app)
  end
end
