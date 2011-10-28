class OneOffs
  def self.add_gamer_job
    Job.create :active => true,
      :job_type => 'master',
      :controller => 'master_delete_gamers',
      :action => 'index',
      :frequency => 'daily',
      :seconds => 3600
  end
end
