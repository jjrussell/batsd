class Job::QueueUpdatePapayaUserCountController < Job::SqsReaderController

  def initialize
    super QueueNames::UPDATE_PAPAYA_USER_COUNT
  end

  private

  def on_message(message)
    Papaya.update_apps
    OfferCacher.cache_papaya_offers
  end

end
