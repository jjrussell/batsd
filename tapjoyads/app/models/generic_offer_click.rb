class GenericOfferClick < SimpledbShardedResource
  
  belongs_to :click, :foreign_key => 'click_id'

  self.num_domains = NUM_GENERIC_OFFER_CLICK_DOMAINS
  self.sdb_attr :click_id

  def initialize(options = {})
    super({ :load_from_memcache => false }.merge(options))
  end
  
  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_GENERIC_OFFER_CLICK_DOMAINS

    "generic_offer_clicks_#{domain_number}"
  end

  def serial_save(options = {})
    super({ :write_to_memcache => false }.merge(options))
  end

end
