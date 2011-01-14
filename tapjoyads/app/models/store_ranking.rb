class StoreRanking < SimpledbResource
  
  self.domain_name = 'store_rankings'
  
  self.sdb_attr :ranks, :type => :json, :default_value => {}
  
  def initialize(options = {})
    super({ :load_from_memcache => false }.merge(options))
  end
  
  def serial_save(options = {})
    super({ :write_to_memcache => false }.merge(options))
  end
end