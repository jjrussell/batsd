class OneOffs
  def self.fill_empty_creative_queue_times
    CreativeApprovalQueue.update_all('created_at = NOW()', 'created_at IS NULL')
  end
end
