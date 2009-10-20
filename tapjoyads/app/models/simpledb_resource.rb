class SimpledbResource  
  include Amazon::SDB
  
  attr_accessor :domain, :item
  
  def initialize(domain_name, item_key)
    @base = Base.new(ENV['AMAZON_ACCESS_KEY_ID'], ENV['AMAZON_SECRET_ACCESS_KEY'])
    @domain = @base.domain(domain_name)
    @item = Item.new(@domain, item_key)
    
    # Attempt to load the item attributes from the cache. If they are not found,
    # they will automatically be loaded from simpledb.
    begin
      @item.attributes = CACHE.get(get_memcache_key)
    rescue Memcached::NotFound
      begin
        @item.reload!
      rescue
        @item.attributes = Multimap.new
      end
    end
  end
  
  def save
    @item.attributes['updated-at'] = Time.now.iso8601
    @item.save
    CACHE.set(get_memcache_key, @item.attributes, 1.hour)
  end
  
  def box_usage
    @base.box_usage
  end
  
  def get(attr_name)
    @item.attributes.get(attr_name, {:force_array => true})
  end
  
  def put(attr_name, value)
    @item.reload! if @item.empty?
    @item.attributes.put(attr_name, value, {:replace => false})
  end
  
  def put_all(attr_name, values)
    @item.reload! if @item.empty?
    @item.attributes.put(attr_name, values, {:replace => true})
  end
  
  private
  
  def get_memcache_key
    "sdb.#{@domain.name}.#{@item.key}"
  end
end