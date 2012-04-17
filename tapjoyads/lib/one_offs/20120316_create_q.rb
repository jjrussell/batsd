class OneOffs
  def self.create_q
    Sqs.create_queue(QueueNames::SUSPICIOUS_GAMERS, 30)
  end
end
