class OneOffs
  def self.add_cache_optimized_offer_list_queue
    Sqs.create_queue(QueueNames::CACHE_OPTIMIZED_OFFER_LIST, 60)
  end
end
