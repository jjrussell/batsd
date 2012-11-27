class GameState < SimpledbShardedResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "game_states"

  # key format: app_id.publisher_user_id

  self.num_domains = NUM_GAME_STATE_DOMAINS
  self.sdb_attr :tapjoy_points, :type => :int, :default_value => 0
  self.sdb_attr :version, :type => :int, :default_value => 0
  self.sdb_attr :udids, :force_array => true, :replace => false
  self.sdb_attr :tapjoy_device_ids, :force_array => true, :replace => false

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % GameState.num_domains
    "game_states_#{domain_number}"
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

  def tapjoy_device_ids
    get('tapjoy_device_ids', :force_array => true) || udids
  end

  def add_device(device_id)
    put('tapjoy_device_ids', device_id, :replace => false) unless tapjoy_device_ids.include?(device_id)
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

end
