class Job::QueueUpdatePapayaUserCountController < Job::SqsReaderController

  def initialize
    super QueueNames::UPDATE_PAPAYA_USER_COUNT
  end

  private

  def on_message(message)
    date_str = message.body
    Papaya.update_device_by_date(date_str)
  end

end
