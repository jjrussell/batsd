##
# Represents a single web request.
class WebRequest < SimpledbResource
  
  def initialize(path)
    now = Time.now.utc
    date = now.iso8601[0,10]
    
    key = UUIDTools::UUID.random_create.to_s
    
    num = rand(MAX_WEB_REQUEST_DOMAINS)
    
    domain_name = "web-request-#{date}-#{num}"
    
    super domain_name, key, {:load => false}
    
    put('path', path)
    put('time', now.to_f.to_s)
  end
  
  def save
    super({:write_to_memcache => false})
  end
end