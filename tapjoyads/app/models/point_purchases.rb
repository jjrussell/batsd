##
# Store information about a single udid's currency, virtual good purchases, and challenges 
# for a single app.
class PointPurchases < SimpledbResource
  self.key_format = "udid.app_id"
  
  def dynamic_domain_name
    domain_number = @key.hash % NUM_POINT_PURCHASES_DOMAINS
    
    return "point_purchases_#{domain_number}"
  end
  
  
  def add_virtual_good(virtual_good_key)
    virtual_goods_string = get('virtual_goods') || '{}'
    user_virtual_goods = JSON.parse(virtual_goods_string)

    if user_virtual_goods[virtual_good_key]
      user_virtual_goods[virtual_good_key] += 1
    else
      user_virtual_goods[virtual_good_key] = 1
    end
    put('virtual_goods', user_virtual_goods.to_json)
  end
  
end