##
# Store information about a single udid's currency, virtual good purchases, and challenges 
# for a single app.
class PointPurchases < SimpledbResource
  self.key_format = "udid.app_id"
  
  self.sdb_attr :points,        :type => :int
  self.sdb_attr :virtual_goods, :type => :json, :default_value => {}
  
  def initialize(options = {})
    super({:load_from_memcache => false}.merge(options))
    
    if self.points.nil?
      Rails.logger.info "getting initial_balance from currency"
      app_key = @key.split('.')[1]
      currency = Currency.find_in_cache_by_app_id(app_key)
      self.points = currency.initial_balance
    end
  end
  
  def dynamic_domain_name
    domain_number = @key.hash % NUM_POINT_PURCHASES_DOMAINS
    
    return "point_purchases_#{domain_number}"
  end
  
  def add_virtual_good(virtual_good_key)
    user_virtual_goods = self.virtual_goods

    if user_virtual_goods[virtual_good_key]
      user_virtual_goods[virtual_good_key] += 1
    else
      user_virtual_goods[virtual_good_key] = 1
    end
    
    self.virtual_goods = user_virtual_goods
  end
  
  def get_virtual_good_quantity(virtual_good_key)
    return virtual_goods[virtual_good_key] || 0
  end
  
  def get_udid
    @key.split('.')[0]
  end
end