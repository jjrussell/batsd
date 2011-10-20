class GameState < SimpledbShardedResource
  # key format: app_id.publisher_user_id

  self.num_domains = NUM_GAME_STATE_DOMAINS
  self.sdb_attr :tapjoy_points, :type => :int, :default_value => 0
  self.sdb_attr :version, :type => :int, :default_value => 0
  self.sdb_attr :udids, :force_array => true, :replace => false

  # TO REMOVE: after resharding
  attr_reader :attributes_to_replace

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % GameState.num_domains
    "game_states_#{domain_number}"
  end

  def initialize(options = {})
    super({:load_from_memcache => false}.merge(options))
    # TO REMOVE: after resharding
    if new_record?
      correct_domain_name = @this_domain_name
      old_domain_name = "game_states_#{@key.matz_silly_hash % 2}"
      super({:load_from_memcache => false, :domain_name => old_domain_name}.merge(options))
      @this_domain_name = correct_domain_name
      @attributes_to_replace = @attributes unless new_record?
    end
  end

  def seconds_elapsed
    if updated_at
      (Time.zone.now - updated_at).to_i
    else
      0
    end
  end

  def app_id
    key.split(".", 2).first
  end

  def publisher_user_id
    key.split(".", 2).last
  end

  def add_device(udid)
    self.udids = udid unless udids.include? udid
  end

  def data
    data_hash = {}
    attributes.each do |k, v|
      next if !k.starts_with?('d_') || k.ends_with?('_')
      data_hash[k[2..-1]] = get(k)
    end
    data_hash
  end

  def data=(data_hash = {})
    data_hash.each do |k, v|
      put "d_#{k}", v
    end
  end

  def serial_save(options = {})
    super({:write_to_memcache => false}.merge(options))
  end

end
