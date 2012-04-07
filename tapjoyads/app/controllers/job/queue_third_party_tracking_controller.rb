class Job::QueueThirdPartyTrackingController < Job::SqsReaderController
  def initialize
    super QueueNames::THIRD_PARTY_TRACKING
  end

  private

  def on_message(message)
    message = Marshal.restore(Base64::decode64(message.body))

    headers = message[:forwarded_headers]
    headers['Referer'] = message[:orig_url]

    # simulate an <img> pixel tag client-side web call...
    # we lose cookie functionality, unless we implement cookie storage on our end...
    sess = Patron::Session.new
    response = sess.get(message[:url], headers)

    raise "Error hitting third party tracking url: #{message[:url]}" unless response.status == 200
  end
end
