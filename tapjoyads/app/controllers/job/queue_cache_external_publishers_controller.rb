class Job::QueueCacheExternalPublishersController < Job::SqsReaderController

  def initialize
    super QueueNames::CACHE_EXTERNAL_PUBLISHERS
  end

  private

  def on_message(message)
    ExternalPublisher.cache
    Downloader.post(update_hurricane_path, sign_request({}))
  end

  def sign_request(params)
    Signage::ExpiringSignature.new(
      'hmac_sha256',
      Rails.configuration.tapjoy_api_key
    ).sign_hash!(params)
  end

  def hurricane_path
    "#{Rails.configuration.hurricane_api_url}/api/data/external_apps/update_in_network_app"
  end
end
