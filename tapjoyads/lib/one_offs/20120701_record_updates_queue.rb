class OneOffs
  def self.add_record_updates_queue
    Sqs.create_queue('RecordUpdates', 30)
    Job.create!(:active => true, :job_type => 'queue', :controller => 'queue_record_updates', :action => 'index', :frequency => 'interval', :seconds => '0')
  end
end
