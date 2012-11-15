class OneOffs
  def self.create_notification_queue
    Sqs.create_queue(QueueNames::CONVERSION_NOTIFICATIONS, 60)
  end
end
