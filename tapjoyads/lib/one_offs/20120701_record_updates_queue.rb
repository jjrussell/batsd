class OneOffs
  def self.add_record_updates_queue
    Sqs.create_queue('RecordUpdates', 30)
  end
end
