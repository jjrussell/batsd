class Job::QueueCacheRecordNotFoundController < Job::SqsReaderController
  def initialize
    super QueueNames::CACHE_RECORD_NOT_FOUND
  end

  private

  def on_message(message)
    data = JSON.load(message.body)
    object = data["model_name"].constantize.find_by_id(data["id"])
    object.cache unless object.nil?
  end
end
