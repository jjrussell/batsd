class SimpledbResource  
  include Amazon::SDB
  
  attr_accessor :domain, :item
  
  def initialize(domain_name, item_key)
    @base = Base.new(ENV['AMAZON_ACCESS_KEY_ID'], ENV['AMAZON_SECRET_ACCESS_KEY'])
    @domain = @base.domain(RUN_MODE_PREFIX + domain_name)
    @item = Item.new(@domain, item_key)
    
    # Attempt to load the item attributes from the cache. If they are not found,
    # they will attempt be loaded from simpledb. If thet are still not found,
    # a new multimap will be created.
    begin
      @item.attributes = CACHE.get(get_memcache_key)
    rescue Memcached::NotFound
      begin
        @item.reload!
      rescue ParameterError => e
        if (e.to_s.starts_with? 'NoSuchDomain')
          @base.create_domain(@domain.name)
          @item.attributes = Multimap.new
        else
          raise e
        end
      rescue RecordNotFoundError
        @item.attributes = Multimap.new
      end
    end
  end
  
  ##
  # Updates the 'updated-at' attribute of this item, and saves it to SimpleDB.
  # Potentially throws a ServerError if the save fails.
  def save
    @item.attributes['updated-at'] = Time.now.iso8601
    @item.save
    CACHE.set(get_memcache_key, @item.attributes, 1.hour)
  end
  
  ##
  # Returns the sdb box usage since this object was created.
  def box_usage
    @base.box_usage
  end
  
  ##
  # Gets value(s) for a given attribute name.
  def get(attr_name, options = {:force_array => false})
    @item.attributes.get(attr_name, options)
  end
  
  ##
  # Puts a value to be associated with an attribute name.
  def put(attr_name, value, options = {:replace => true})
    @item.attributes.put(attr_name, value, options)
  end
  
  private
  
  def get_memcache_key
    "sdb.#{@domain.name}.#{@item.key}"
  end
end