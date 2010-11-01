##
# Store information about a single udid's currency, virtual good purchases, and challenges 
# for a single app.
class PointPurchases < SimpledbShardedResource
  self.key_format = "udid.app_id"
  self.num_domains = NUM_POINT_PURCHASES_DOMAINS
  
  self.sdb_attr :points,        :type => :int
  self.sdb_attr :virtual_goods, :type => :json, :default_value => {}
  
  def initialize(options = {})
    super({:load_from_memcache => false}.merge(options))
    
    if self.points.nil?
      Rails.logger.info "getting initial_balance from currency"
      app_key = @key.split('.')[1]
      currency = Currency.find_in_cache(app_key)
      if currency.nil?
        Rails.logger.info "Unkown app id for key: #{key}"
        self.points = 0
      else
        self.points = currency.initial_balance
      end
    end
  end
  
  def dynamic_domain_name
    domain_number = @key.hash % NUM_POINT_PURCHASES_DOMAINS
    
    return "point_purchases_#{domain_number}"
  end
  
  def add_virtual_good(virtual_good_key, quantity = 1)
    user_virtual_goods = self.virtual_goods

    if user_virtual_goods[virtual_good_key]
      user_virtual_goods[virtual_good_key] += quantity
    else
      user_virtual_goods[virtual_good_key] = quantity
    end
    
    self.virtual_goods = user_virtual_goods
  end
  
  def get_virtual_good_quantity(virtual_good_key)
    return virtual_goods[virtual_good_key] || 0
  end
  
  def get_udid
    @key.split('.')[0]
  end
  
  def self.purchase_virtual_good(key, virtual_good_key, quantity = 1)
    virtual_good = VirtualGood.new(:key => virtual_good_key)
    raise UnknownVirtualGood.new if virtual_good.is_new
    
    message = ''
    PointPurchases.transaction(:key => key) do |point_purchases|
      Rails.logger.info "Purchasing virtual good for price: #{virtual_good.price}, from user balance: #{point_purchases.points}"
      raise TooManyPurchases.new if virtual_good.max_purchases > 0 && point_purchases.get_virtual_good_quantity(virtual_good.key) >= virtual_good.max_purchases
      
      point_purchases.add_virtual_good(virtual_good.key, quantity)
      point_purchases.points = point_purchases.points - (virtual_good.price * quantity)
      
      raise BalanceTooLowError.new if point_purchases.points < 0
      message = "You successfully purchased #{virtual_good.name}"
    end
    
    return true, message, virtual_good.name
  rescue RightAws::AwsError
    return false, "Error contacting backend datastore"
  rescue BalanceTooLowError, UnknownVirtualGood, TooManyPurchases => e
    return false, e.to_s, virtual_good.name
  end
  
private
  
  class TooManyPurchases < RuntimeError
    def to_s; "You have already purchased this item the maximum number of times"; end
  end
  class BalanceTooLowError < RuntimeError
    def to_s; "Balance too low"; end
  end
  class UnknownVirtualGood < RuntimeError;
    def to_s; "Unknown virtual good"; end
  end
end