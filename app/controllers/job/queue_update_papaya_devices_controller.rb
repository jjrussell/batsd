class Job::QueueUpdatePapayaDevicesController < Job::SqsReaderController

  def initialize
    super QueueNames::UPDATE_PAPAYA_DEVICES
  end

  private

  def on_message(message)
    date_str = message.body
    Papaya.update_devices_by_date(date_str)
  end

end
