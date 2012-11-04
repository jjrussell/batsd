class Job::QueueRecordUpdatesController < Job::SqsReaderController

  def initialize
    super QueueNames::RECORD_UPDATES
  end

  private

  def on_message(message)
    message = Marshal.restore_with_ensure_utf8(Base64::decode64(message.body))

    # example: App.find(1).update_attributes!({ :name => 'Test App' })
    message[:class_name].constantize.find(message[:id]).update_attributes!(message[:attributes])
  end

end
