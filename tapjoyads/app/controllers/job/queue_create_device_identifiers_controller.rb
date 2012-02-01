class Job::QueueCreateDeviceIdentifiersController < Job::SqsReaderController

  def initialize
    super QueueNames::CREATE_DEVICE_IDENTIFIERS
  end

  private

  def on_message(message)
    json = JSON.load(message.body)
    device = Device.find(json['device_id'], :consistent => true)
    return if device.nil?
    device.create_identifiers!
  end

end
