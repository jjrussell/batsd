class OneOffs
  def self.remove_unused_queues
    Sqs.queue(QueueNames::THIRD_PARTY_TRACKING).delete
    Sqs.queue(QueueNames::FAILED_DOWNLOADS).delete
  end
end
