class OneOffs
  def self.add_coupon_email_queue
    Sqs.create_queue(QueueNames::SEND_COUPON_EMAILS, 60)
  end
end
