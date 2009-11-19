##
# Represents a single web request.
class WebRequest < SimpledbResource
  
  def initialize(path)
    now = Time.now.utc
    date = now.iso8601[0,10]
    
    key = UUIDTools::UUID.random_create.to_s
    domain_name = "web-request-#{date}"
    
    super domain_name, key, false
    
    put('path', path)
    put('time', now.to_f.to_s)
  end
  
  def save
    super false
  end
end