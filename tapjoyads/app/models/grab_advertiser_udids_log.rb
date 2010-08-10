class GrabAdvertiserUdidsLog < SimpledbResource
  self.domain_name = 'grab_advertiser_udids_logs'
  
  self.sdb_attr :offer_id
  self.sdb_attr :start_time,      :type => :int
  self.sdb_attr :finish_time,     :type => :int
  self.sdb_attr :job_started_at,  :type => :date
  self.sdb_attr :job_finished_at, :type => :date
  self.sdb_attr :job_requeued_at, :type => :date
  
  def initialize(options = {})
    super({ :load_from_memcache => false }.merge(options))
  end
  
  def serial_save(options = {})
    super({ :write_to_memcache => false }.merge(options))
  end
  
end
