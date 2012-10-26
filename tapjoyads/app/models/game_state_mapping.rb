class GameStateMapping < SimpledbShardedResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "game_state_mappings"

  # key format: app_id.(udid | facebook_id)

  self.num_domains = NUM_GAME_STATE_MAPPING_DOMAINS

  self.sdb_attr :publisher_user_id

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % GameStateMapping.num_domains
    "game_state_mappings_#{domain_number}"
  end

  def generate_publisher_user_id!
    self.publisher_user_id = UUIDTools::UUID.random_create.to_s
    self.save
  end

end
