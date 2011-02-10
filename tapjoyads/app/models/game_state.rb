class GameState < SimpledbShardedResource
  # key format: app_id.publisher_user_id
  
  self.num_domains = NUM_GAME_STATE_DOMAINS
  self.sdb_attr :data
  self.sdb_attr :tapjoy_spend, :type => :int, :default_value => 0
  self.sdb_attr :version, :type => :int, :default_value => 0
  
  def dynamic_domain_name
    domain_number = @key.hash % GameState.num_domains
    "game_states_#{domain_number}"
  end

  def initialize(options = {})
    super({:load_from_memcache => false}.merge(options))
  end
  
  def seconds_elapsed
    if updated_at
      (Time.zone.now - updated_at).to_i
    else
      0
    end
  end
  
  def app_id
    key.split(".").first
  end
  
  def publisher_user_id
    key.split(".").last
  end
  
  def udids
    get('udids', :force_array => true)
  end
  
  def add_device(udid)
    put('udids', udid, :replace => false) unless udids.include? udid
  end
  
end
