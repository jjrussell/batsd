class Job::QueueUpdateNonHtmlResponsesController < Job::SqsReaderController

  def initialize
    super QueueNames::UPDATE_NON_HTML_RESPONSES
  end

  private

  def on_message(message)
    message = Marshal.restore(Base64::decode64(message.body))
    App.find(message[:publisher_app_id]).update_attributes!(:uses_non_html_responses => message[:bool])
  end

end
