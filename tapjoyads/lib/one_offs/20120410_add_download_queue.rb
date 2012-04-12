class OneOffs
  def self.add_download_queue
    Sqs.create_queue('Downloads', 45)
    Job.create!(:active => true, :job_type => 'queue', :controller => 'queue_downloads', :action => 'index', :frequency => 'interval', :seconds => '10')
  end
end
