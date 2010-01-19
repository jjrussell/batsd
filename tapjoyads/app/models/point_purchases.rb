##
# Store information about a single udid's currency, virtual good purchases, and challenges 
# for a single app.
class PointPurchases < SimpledbResource
  self.key_format = "udid.app_guid"
  
  def dynamic_domain_name
    domain_number = @key.hash % 10
    
    return "point_purchases_#{domain_number}"
  end
  
end