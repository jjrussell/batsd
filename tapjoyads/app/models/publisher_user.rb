class PublisherUser < SimpledbShardedResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "publisher_users", :read_from_riak => true

  MAX_TAPJOY_DEVICE_IDS = 5

  self.num_domains = NUM_PUBLISHER_USER_DOMAINS

  self.sdb_attr :udids, :force_array => true, :replace => false
  self.sdb_attr :tapjoy_device_ids, :force_array => true, :replace => false

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_PUBLISHER_USER_DOMAINS
    "publisher_users_#{domain_number}"
  end

  def initialize(options = {})
    super({ :load_from_memcache => true }.merge(options))
  end

  def save(options = {})
    super({ :write_to_memcache => true }.merge(options))
  end

  def tapjoy_device_ids
    get('tapjoy_device_ids', :force_array => true).present? ? get('tapjoy_device_ids', :force_array => true) : udids
  end

  def attribute_name
    get('tapjoy_device_ids', :force_array => true).present? ? 'tapjoy_device_ids' : 'udids'
  end

  def update!(device_id)
    return false if tapjoy_device_ids.length >= MAX_TAPJOY_DEVICE_IDS
    return true  if tapjoy_device_ids.include?(device_id)

    put('tapjoy_device_ids', device_id, :replace => false)
    save

    tapjoy_device_ids.length < MAX_TAPJOY_DEVICE_IDS
  end

  def remove!(device_id)
    if tapjoy_device_ids.include?(device_id)
      self.delete(attribute_name, device_id)
      save
    end
  end

  def self.for_click(click)
    PublisherUser.new(:key => "#{click.publisher_app_id}.#{click.publisher_user_id}")
  end
end
