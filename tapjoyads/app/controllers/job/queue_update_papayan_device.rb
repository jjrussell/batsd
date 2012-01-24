class Job::QueuePapayanDeviceController < Job::SqsReaderController

  def initialize
    super QueueNames::UPDATE_PAPAYAN_DEVICE
  end

  private

  def on_message(message)
    date_str = message.body
    Papaya.update_device_by_date(date_str)
  end

end
