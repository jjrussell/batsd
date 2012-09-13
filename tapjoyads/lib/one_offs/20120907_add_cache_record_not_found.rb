class OneOffs
  def self.add_cache_record_not_found
    Sqs.create_queue(QueueNames::CACHE_RECORD_NOT_FOUND, 60)
  end
end
