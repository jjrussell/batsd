class User < SimpledbResource
  def initialize(key, options = {})
    super 'user', key, options
  end
  
  #TODO: just a sample implementation of to_xml feel free to comment it out  
  def to_xml
    attr_hash = Hash.new    
    attributes.each_pair do |key, value|
      unless key == "id"
         value.is_a?(Array) ? attr_hash.store(key, value.first) : attr_hash.store(key, value)      
      end
    end
    attr_hash.store("id", attr_hash["user_id"])
    attr_hash.to_xml(:root => "user")  
  end
  
end