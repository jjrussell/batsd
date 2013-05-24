class OneOffs
  def self.add_cache_support_request_stat_queue
    #Sqs.create_queue(QueueNames::CACHE_SUPPORT_REQUEST_STATS, 60)
    Job.create!(:active => true,
                :job_type => 'queue',
                :controller => 'queue_cache_support_request_stats',
                :action => 'index',
                :frequency => 'hourly',
                :seconds => '1620'
               )
  end
end
