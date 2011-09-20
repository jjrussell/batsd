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
      app_key = @key.split('.').last
      currency = Currency.find_in_cache(app_key)
      raise "unable to determine initial balance for #{app_key}" if currency.nil?
      self.points = currency.initial_balance
    end
  end
  
  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_POINT_PURCHASES_DOMAINS
    
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
    @key.split('.')[0..-2].join('.')
  end
  
  def self.purchase_virtual_good(key, virtual_good_key, quantity = 1)
    raise QuantityTooLowError if quantity < 1
    virtual_good = VirtualGood.new(:key => virtual_good_key)
    raise UnknownVirtualGood if virtual_good.is_new
    
    message = ''
    pp = PointPurchases.transaction(:key => key) do |point_purchases|
      Rails.logger.info "Purchasing virtual good for price: #{virtual_good.price}, from user balance: #{point_purchases.points}"
      
      point_purchases.add_virtual_good(virtual_good.key, quantity)
      point_purchases.points = point_purchases.points - (virtual_good.price * quantity)
      
      raise TooManyPurchases if virtual_good.max_purchases > 0 && point_purchases.get_virtual_good_quantity(virtual_good.key) > virtual_good.max_purchases
      raise BalanceTooLowError if point_purchases.points < 0
      message = "You successfully purchased #{virtual_good.name}"
    end
    
    return true, message, pp
  rescue RightAws::AwsError
    return false, "Error contacting backend datastore"
  rescue BalanceTooLowError, UnknownVirtualGood, TooManyPurchases, QuantityTooLowError => e
    return false, e.to_s
  end
  
  def self.spend_points(key, points)
    message = ''
    pp = PointPurchases.transaction(:key => key) do |point_purchases|
      point_purchases.points = point_purchases.points - points
      
      raise BalanceTooLowError if point_purchases.points < 0
      message = "You successfully spent #{points} points"
    end
    
    return true, message, pp
  rescue RightAws::AwsError
    return false, "Error contacting backend datastore"
  rescue BalanceTooLowError => e
    return false, e.to_s
  end

  def self.consume_virtual_good(key, virtual_good_key, quantity = 1)
    raise QuantityTooLowError if quantity < 1
    virtual_good = VirtualGood.new(:key => virtual_good_key)
    raise UnknownVirtualGood if virtual_good.is_new

    message = ''
    pp = PointPurchases.transaction(:key => key) do |point_purchases|
      raise NotEnoughGoodsError if quantity > point_purchases.get_virtual_good_quantity(virtual_good.key)
      Rails.logger.info "Using virtual good: used => #{quantity}, remaining => #{point_purchases.get_virtual_good_quantity(virtual_good.key) - quantity}"

      point_purchases.add_virtual_good(virtual_good.key, -quantity)

      message = "You successfully used #{virtual_good.name}"
    end

    return true, message, pp
  rescue RightAws::AwsError
    return false, "Error contacting backend datastore"
  rescue UnknownVirtualGood, NotEnoughGoodsError, QuantityTooLowError => e
    return false, e.to_s
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
  class NotEnoughGoodsError < RuntimeError
    def to_s; "You don't have enough of this item to do that"; end
  end
  class QuantityTooLowError < RuntimeError
    def to_s; "The quantity must be greater than 0"; end
  end
end
