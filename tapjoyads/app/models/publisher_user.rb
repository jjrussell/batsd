class PublisherUser < SimpledbShardedResource
  MAX_UDIDS = 5

  self.num_domains = NUM_PUBLISHER_USER_DOMAINS

  self.sdb_attr :udids, :force_array => true, :replace => false

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

  def update!(udid)
    return false if udids.length >= MAX_UDIDS
    return true  if udids.include?(udid)

    self.udids = udid
    save

    udids.length < MAX_UDIDS
  end

  def self.for_click(click)
    raise "click missing PublisherUser details" unless click.publisher_user_id.present? && click.publisher_app_id.present?
    PublisherUser.new(:key => "#{click.publisher_app_id}.#{click.publisher_user_id}")
  end
end
