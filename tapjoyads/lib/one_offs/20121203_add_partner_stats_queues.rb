class OneOffs
  def self.add_partner_stats_queues
    Sqs.create_queue(QueueNames::PARTNER_STATS_DAILY, 600)
    Sqs.create_queue(QueueNames::PARTNER_STATS_HOURLY, 600)
  end
end
