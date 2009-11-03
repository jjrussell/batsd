class SimpledbResource  
  include Amazon::SDB
  
  attr_accessor :domain, :item
  
  def initialize(domain_name, item_key)
    @base = Base.new(ENV['AMAZON_ACCESS_KEY_ID'], ENV['AMAZON_SECRET_ACCESS_KEY'])
    @domain = @base.domain(domain_name)
    @item = Item.new(@domain, item_key)
    
    # Attempt to load the item attributes from the cache. If they are not found,
    # they will attempt be loaded from simpledb. If thet are still not found,
    # a new multimap will be created.
    begin
      @item.attributes = CACHE.get(get_memcache_key)
    rescue Memcached::NotFound
      begin
        @item.reload!
      rescue RecordNotFoundError
        @item.attributes = Multimap.new
      end
    end
  end
  
  ##
  # Updates the 'updated-at' attribute of this item, and saves it to SimpleDB.
  # If the item fails to save, then it will be retried, with exponential backoff.
  # For this reason, this method should never be called from a request thread, because
  # it may take a long time to complete.
  def save
    is_saved = false
    sleep_time = 1
    until is_saved
      begin
        @item.attributes['updated-at'] = Time.now.iso8601
        @item.save
        is_saved = true
      rescue ServerError
        logger.warn "ServerError when trying to save. Sleeping for #{sleep_time} seconds before retrying."
        sleep(sleep_time)
        sleep_time *= 2
      end
    end
    CACHE.set(get_memcache_key, @item.attributes, 1.hour)
  end
  
  def box_usage
    @base.box_usage
  end
  
  def get(attr_name)
    @item.attributes.get(attr_name, {:force_array => true})
  end
  
  def put(attr_name, value)
    @item.attributes.put(attr_name, value, {:replace => false})
  end
  
  def put_all(attr_name, values)
    @item.attributes.put(attr_name, values, {:replace => true})
  end
  
  private
  
  def get_memcache_key
    "sdb.#{@domain.name}.#{@item.key}"
  end
end