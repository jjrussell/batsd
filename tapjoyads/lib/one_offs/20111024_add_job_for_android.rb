class OneOffs
  def self.add_android_job
    Job.create :active => true,
      :job_type => 'master',
      :controller => 'master_android_market_format',
      :action => 'index',
      :frequency => 'hourly',
      :seconds => 60 * 10
  end
end
