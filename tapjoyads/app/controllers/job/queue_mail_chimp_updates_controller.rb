class Job::QueueMailChimpUpdatesController < Job::SqsReaderController

  def initialize
    super QueueNames::MAIL_CHIMP_UPDATES
  end

private

  def on_message(message)
    message = JSON.load(message.to_s)
    MailChimp.update(message["email"], message["field"], message["new_value"])
  end
end
