class OneOffs
  def self.create_new_advertising_ids_queue
    Sqs.create_queue(QueueNames::NEW_ADVERTISING_IDS, 60)
  end
end
