class Job::QueueNewAdvertisingIdsController < Job::SqsReaderController

  def initialize(queue_name = QueueNames::NEW_ADVERTISING_IDS)
    super queue_name
    @raise_on_error = false
  end

  private

  def on_message(message)
    json = JSON.load(message.body)
    device = Device.find(json['device_id'], :consistent => true)
    return if device.nil? || !device.advertising_id_device?

    device.load_historical_data!
  end
end
